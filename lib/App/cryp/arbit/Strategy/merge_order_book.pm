package App::cryp::arbit::Strategy::merge_order_book;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Finance::Currency::FiatX;

use Role::Tiny::With;

with 'App::cryp::Role::ArbitStrategy';

sub create_order_pairs {
    my ($pkg, %args) = @_;

    my $r = $args{r};
    my $dbh = $r->{_stash}{dbh};

    #my $accbals = App::cryp::arbit::_get_account_balances($r);

    my @order_pairs;

  COIN:
    for my $coin (@{ $r->{_stash}{coins} }) {
        log_info "Listing orderbooks for coin %s ...", $coin;

        my %prices; # key = exchange_id, val = price in USD
        my %vols  ; # key = exchange_id, val = volume in USD

        my %sells; # key = exchange_id, val = [[lowest-price-in-USD , amount-of-coin, orig-fiat-currency, price-in-orig-fiat-currency], [2nd-lowest-price-in-USD , amount-of-currency, ...], ...]
        my %buys ; # key = exchange_id, val = [[highest-price-in-USD, amount-of-coin, orig-fiat-currency, price-in-orig-fiat-currency], [2nd-highest-price-in-USD, amount-of-currency, ...], ...]

        # get order books
      EXCHANGE:
        for my $exchange (sort keys %{ $r->{_stash}{exchange_clients} }) {
            my $eid = App::cryp::arbit::_get_exchange_id($r, $exchange);
            my $clients = $r->{_stash}{exchange_clients}{$exchange};
            my $client = $clients->{ (sort keys %$clients)[0] };

          PAIR:
            my $pairs = $r->{_stash}{exchange_pairs}{$exchange};
            for my $pair (@$pairs) {
                my ($cur1, $cur2) = split m!/!, $pair;
                next unless $cur1 eq $coin;
                next unless App::cryp::arbit::_is_fiat($cur2);
                if ($r->{args}{fiats}) {
                    next unless grep { $_ eq $cur2 } @{ $r->{args}{fiats} };
                }

                my $time = time();
                log_debug "Getting orderbook %s on %s ...", $pair, $exchange;
                my $res = $client->get_order_book(pair => $pair);
                unless ($res->[0] == 200) {
                    log_error "Couldn't get orderbook %s on %s: %s, skipping this pair",
                        $pair, $exchange, $res;
                    next PAIR;
                }
                #log_trace "orderbook %s on %s: %s", $pair, $exchange, $res->[2]; # too much info to log

                # sanity checks
                unless (@{ $res->[2]{sell} }) {
                    log_warn "No sell orders for %s on %s, skipping this pair",
                        $pair, $exchange;
                    next PAIR;
                }
                unless (@{ $res->[2]{buy} }) {
                    log_warn "No buy orders for %s on %s, skipping this pair",
                        $pair, $exchange;
                    last PAIR;
                }

                # convert fiat to USD
                unless ($cur2 eq 'USD') {
                    my ($fxrate_buy, $fxrate_sell);

                    my $cbuyres  = Finance::Currency::FiatX::convert_fiat_currency(
                        amount => 1, from => $cur2, to => 'USD', dbh => $dbh, type => 'buy');
                    if ($cbuyres->[0] != 200) {
                        log_error "Couldn't get conversion rate (buy) from %s to USD, skipping this pair",
                            $cur2;
                        next PAIR;
                    }
                    $fxrate_buy = $cbuyres->[2];

                    my $csellres = Finance::Currency::FiatX::convert_fiat_currency(
                        amount => 1, from => $cur2, to => 'USD', dbh => $dbh, type => 'sell');
                    if ($csellres->[0] != 200) {
                        log_error "Couldn't get conversion rate (sell) from %s to USD, skipping this pair",
                            $cur2;
                        next PAIR;
                    }
                    $fxrate_sell = $csellres->[2];

                    log_debug "Will be using these conversion rates from %s to USD: buy=%.4f, sell=%.4f",
                        $cur2, $fxrate_buy, $fxrate_sell;

                    for my $rec (@{ $res->[2]{buy} }) {
                        $rec->[2]  = $cur2;
                        $rec->[3]  = $rec->[0];
                        $rec->[0] *= $fxrate_buy;
                    }
                    for my $rec (@{ $res->[2]{sell} }) {
                        $rec->[2]  = $cur2;
                        $rec->[3]  = $rec->[0];
                        $rec->[0] *= $fxrate_sell;
                    }
                } # convert fiat currency

                $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                         $time, $coin, "USD", $res->[2]{buy}[0][0], $eid, "buy");
                $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                         $time, $coin, "USD", $res->[2]{sell}[0][0], $eid, "sell");

                push @{ $sells{$exchange} }, @{ $res->[2]{sell} };
                push @{ $buys {$exchange} }, @{ $res->[2]{buy}  };
            } # for pair
        } # for exchange

        if (keys(%buys) < 2) {
            log_info "There are less than two exchanges that offer buys for %s, ".
                "skipping this coin";
            next COIN;
        }
        if (keys(%sells) < 2) {
            log_debug "There are less than two exchanges that offer asks for %s, skipping this round";
            next CURRENCY;
        }

        # merge all buys from all exchanges, sort from highest price
        my @all_buys;
        for my $exchange (keys %buys) {
            for my $item (@{ $buys{$exchange} }) {
                push @all_buys, [$exchange, @$item];
            }
        }
        @all_buys = sort { $b->[1] <=> $a->[1] } @all_buys;

        # merge all sells from all exchanges, sort from lowest price
        my @all_sells;
        for my $exchange (keys %sells) {
            for my $item (@{ $sells{$exchange} }) {
                push @all_sells, [$exchange, @$item];
            }
        }
        @all_sells = sort { $a->[1] <=> $b->[1] } @all_sells;

        log_debug "all_buys  for %s: %s", $coin, \@all_buys;
        log_debug "all_sells for %s: %s", $coin, \@all_sells;

      ARBITRAGE:
        {
            last unless @all_buys;

            # let's take a look at the highest buyer that we can sell to
            my $exchange_to_sell_to   = $all_buys[0][0];
            my $sell_gross_price      = $all_buys[0][1]; # in USD
            my $sell_amount           = $all_buys[0][2]; # in coin
            my $sell_base_cur         = $all_buys[0][3] // 'USD';
            my $sell_gross_price_base = $all_buys[0][4] // $sell_gross_price;
            my $sell_amount_usd        = $sell_amount * $sell_gross_price;

            # subtract by trading fees, this is the money that we will get by
            # selling
            my $sell_fee_pct = App::cryp::arbit::_get_trading_fee($r, $exchange_to_sell_to, $coin);
            log_debug "Trading fee to sell %s on %s is %.4f%%", $coin, $exchange_to_sell_to, $sell_fee_pct;
            my $sell_net_price = $sell_gross_price * (1 - $sell_fee_pct/100);

            # find coins we can buy from cheaper sellers
            last unless @all_sells;
            my $i = 0;
            while ($i < @all_sells) {
                my $exchange_to_buy_from = $all_sells[$i][0];
                if ($exchange_to_buy_from eq $exchange_to_sell_to) {
                    $i++; next;
                }
                my $buy_gross_price      = $all_sells[$i][1]; # in USD
                my $buy_amount           = $all_sells[$i][2]; # in coin
                my $buy_base_cur         = $all_sells[$i][3] // 'USD';
                my $buy_gross_price_base = $all_sells[$i][4] // $buy_gross_price;
                my $buy_amount_usd       = $buy_amount * $buy_gross_price;

                # add by trading fees, this is the money that we have to spend
                # to buy the coins
                my $buy_fee_pct = App::cryp::arbit::_get_trading_fee($r, $exchange_to_buy_from, $coin);
                log_debug "Trading fee to buy %s on %s is %.4f%%", $coin, $exchange_to_buy_from, $buy_fee_pct;
                my $buy_net_price = $buy_gross_price * (1 + $buy_fee_pct/100);

                my $smaller_price = $sell_net_price < $buy_net_price ? $sell_net_price : $buy_net_price;
                my $profit_pct    = ($sell_net_price - $buy_net_price) / $smaller_price * 100;

                if ($profit_pct <= $r->{args}{min_price_difference_percentage}) {
                    last ARBITRAGE;
                }

                my ($amount, $amount_usd, $which_smaller);
                if ($buy_amount > $sell_amount) {
                    $amount = $sell_amount;
                    $amount_usd = $sell_amount_usd;
                    $which_smaller = 'sell';
                } else {
                    $amount = $buy_amount;
                    $amount_usd = $buy_amount_usd;
                    $which_smaller = 'buy';
                }
                push @order_pairs, {
                    sell => {
                        exchange      => $exchange_to_sell_to,
                        pair          => "$coin/$sell_base_cur",
                        price_usd     => $sell_gross_price,
                        net_price_usd => $sell_net_price,
                        price_base    => $sell_gross_price_base,
                        amount        => $amount,
                    },
                    buy => {
                        exchange      => $exchange_to_buy_from,
                        pair          => "$coin/$buy_base_cur",
                        price_usd     => $buy_gross_price,
                        net_price_usd => $buy_net_price,
                        price_base    => $buy_gross_price_base,
                        amount        => $amount,
                    },
                    profit_pct => $profit_pct,
                    profit_usd => $amount_usd * $profit_pct,
                };
                if ($which_smaller eq 'sell') {
                    # we used up sell orders at this price, remove from
                    # orderbook
                    shift @all_buys;
                    $all_sells[$i][2] -= $amount;
                    splice @all_sells, $i, 1 if abs($all_sells[$i][2]) < 1e-8;
                } else {
                    # we used up sell orders at this price, remove from
                    # orderbook
                    splice @all_sells, $i, 1;
                    $all_buys[0][2] -= $amount;
                    shift @all_buys if abs($all_buys[0][2]) < 1e-8;
                }
            } # while all_sells
        } # ARBITRAGE

    } # for coin

    [200, "OK", \@order_pairs];
}

1;
# ABSTRACT: Using merged order books for arbitration

=head1 SYNOPSIS

=head2 Using this strategy

In your F<cryp.conf>:

 [program=cryp-arbit arbit]
 strategy=merge-order-book

or in your F<cryp-arbit.conf>:

 [arbit]
 strategy=merge-order-book

This is actually the default strategy, so you don't have to explicitly set
C<strategy> to this strategy.

=head2 Configuration

In your F<cryp.conf>:

 [arbit-strategy/merge-order-book]
 ...


=head1 DESCRIPTION

This arbitration strategy uses information from merged order books. Below is the
description of the algorithm. Suppose we are arbitraging the pair BTC/USD.
I<E1>, I<E2<, ... I<En> are exchanges. I<P*> are prices. I<A*> are amounts. I<i>
denotes exchange index.

B<First step:> get order books from all of the involved exchanges, for example:

 # buy orders on E1            # sell orders on E1
 price  amount                 price  amount
 -----  ------                 -----  ------
 P1b1   A1b1                   P1s1   A1s1
 P1b2   A1b2                   P1s2   A1s2
 P1b3   A1b3                   P1s3   A1s3
 ...                           ...

 # buy orders on E2            # sell orders on E2
 price  amount                 price  amount
 -----  ------                 -----  ------
 P2b1   A2b1                   P2s1   A2s1
 P2b2   A2b2                   P2s2   A2s2
 P2b3   A2b3                   P2s3   A2s3
 ...                           ...

 ...

Note that buy orders are sorted from highest to lowest price (I<Pib1> > I<Pib2>
> I<Pib3> > ...) while sell orders are sorted from lowest to highest price
(I<Pis1> < I<Pis2> < I<Pis3> < ...). Also note that I<P1b*> < I<P1s*>, unless
something weird is going on.

B<Second step:> merge all the orders from exchanges into just two lists: buy and
sell orders. Sort buy orders, as usual, from highest to lowest price. Sort sell
orders, as usual, from lowest to highest. For example:

 # buy orders                  # sell orders
 price  amount                 price  amount
 -----  ------                 -----  ------
 P1b1   A1b1                   P2s1   A2s1
 P2b1   A2b1                   P3s1   A3s1
 P2b2   A2b2                   P3s2   A3s2
 P1b2   A1b2                   P1s1   A1s1
 ...

Arbitrage can happen if we can buy cheap bitcoin and sell our expensive bitcoin.
This means I<P1b1> must be I<above> I<P2s1>, because we want to buy bitcoins on
I<E1> from trader that is willing to sell at I<P2s1> then sell it on I<E1> to
the trader that is willing to buy the bitcoins at I<P2b1>. Pocketing the
difference (minus trading fees) as profit.

No actual bitcoins will be transferred from I<E2> to I<E1> as that would take a
long time and incurs relatively high network fees. Instead, we maintain bitcoin
and USD balances on each exchange to be able to buy/sell quickly. The balances
serve as "working capital" or "inventory".

The minimum percentage difference is I<min_price_difference_percentage>. We
create buy/sell order pairs starting from the topmost of the merged order book,
until we can't get I<min_price_difference_percentage> anymore.

Then we monitor our order pairs and cancel them if they remain unfilled for a
while.

Then we retrieve order books from the exchanges and start the process again.


=head2 Strengths

Order books contain information about prices and volumes at each price level.
This serves as a guide on what size our orders should be, so we do not have to
explicitly set order size. This is especially useful if we are not familiar with
the typical volume of the pair on an exchange.

By sorting the buy and sell orders, we get maximum price difference.


=head1 Weaknesses

Order books are changing rapidly. By the time we get the order book from the
exchange API, that information is already stale. In the course of milliseconds,
the order book can change, sometimes significantly. So when we submit an order
to buy X BTC at price P, it might not get fulfilled completely or at all because
the market price has moved above P, for example.


=head1 METHODS

=head2 create_order_pairs

Usage:

  __PACKAGE__->create_order_pairs(%args) => [$status, $reason, $payload, \%resmeta]

Known arguments are those specified in L<App::cryp::Role::ArbitStrategy>, plus:

=over

=item * order_books

Optional. Hash. If unset, will be requested from the exchange API clients.

Keys are exchange shortnames, values are hashes. Each hash is of the following
structure:

 {
   request_time  => $req_epoch, # when we request the order book, hires
   response_time => $res_epoch, # when we get the order book response, hires
   response      => $env_result,
 }

The response (C<$env_result>) is what is returned by the C<get_order_book()>
method or a C<App::cryp::Exchange::*> module (see L<App::cryp::Role::Exchange>).
Particularly, the payload of the response is something of the following
structure:

 {buy => [
     # sorted from the highest price
     [$buyprice1, $buyamount1],
     [$buyprice2, $buyamount2],
     ,,,
  ],
  sell => [
     # sorted from the lowest price
     [$sellprice1, $sellamount1],
     [$sellprice2, $sellamount2],
     ,,,
  ]}

=back


=head1 INTERNAL NOTES

For ease of testing, all the required information should be passed as arguments
instead of having to be retrieved from the database.


=head1 SEE ALSO
