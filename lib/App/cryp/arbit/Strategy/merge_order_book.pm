package App::cryp::arbit::Strategy::merge_order_book;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Finance::Currency::FiatX;
use List::Util qw(min max);

use Role::Tiny::With;

with 'App::cryp::Role::ArbitStrategy';

sub _create_order_pairs {
    my %args = @_;

    my $coin             = $args{coin};
    my $all_buy_orders   = $args{all_buy_orders};
    my $all_sell_orders  = $args{all_sell_orders};
    my $min_profit_pct   = $args{min_profit_pct};
    # TODO args{max_orders_amount_per_round}
    # TODO args{max_order_pairs_per_round}

    my @order_pairs;

  CREATE:
    while (1) {
        last unless @$all_buy_orders;

        # let's take a look at the highest buyer that we can sell to
        my $sell = $all_buy_orders->[0];

        # find coins we can buy from cheaper sellers
        last unless @$all_sell_orders;

        my $i = 0;
        my $buy;
        while ($i < @$all_sell_orders) {
            $buy = $all_sell_orders->[$i];
            # shouldn't happen though
            if ($buy->{exchange} eq $sell->{exchange}) {
                $i++; next;
            }
            last;
        }
        # exit when we can no longer find any seller we can buy chaper coin from
        last CREATE unless $i < @$all_sell_orders;
        my $smaller_price = min($sell->{net_price_usd}, $buy->{net_price_usd});
        my $profit_pct    = ($sell->{net_price_usd} - $buy->{net_price_usd}) /
            $smaller_price * 100;
        log_trace "profit_pct=%.4f", $profit_pct;
        last CREATE if $profit_pct < $min_profit_pct;

        push @order_pairs, {
            sell => {
                exchange         => $sell->{exchange},
                pair             => "$coin/$sell->{currency}",
                gross_price_orig => $sell->{gross_price_orig},
                gross_price_usd  => $sell->{gross_price_usd},
                net_price_orig   => $sell->{net_price_orig},
                net_price_usd    => $sell->{net_price_usd},
            },
            buy => {
                exchange         => $buy->{exchange},
                pair             => "$coin/$buy->{currency}",
                gross_price_orig => $buy->{gross_price_orig},
                gross_price_usd  => $buy->{gross_price_usd},
                net_price_orig   => $buy->{net_price_orig},
                net_price_usd    => $buy->{net_price_usd},
            },
            profit_pct => $profit_pct,
        };
        if ($sell->{amount} < $buy->{amount}) {
            # we used up all amount from buy order from orderbook at this price,
            # remove from orderbook
            $order_pairs[-1]{buy}{amount}  = $sell->{amount};
            $order_pairs[-1]{sell}{amount} = $sell->{amount};

            shift @$all_buy_orders;
            $all_sell_orders->[$i]{amount} -= $sell->{amount};
            splice @$all_sell_orders, $i, 1
                if abs($all_sell_orders->[$i]{amount}) < 1e-8;
        } else {
            # we used up all amount from sell order from orderbook at this
            # price, remove from orderbook
            $order_pairs[-1]{buy}{amount}  = $buy->{amount};
            $order_pairs[-1]{sell}{amount} = $buy->{amount};

            splice @$all_sell_orders, $i, 1;
            $all_buy_orders->[0]{amount} -= $buy->{amount};
            shift @$all_buy_orders
                if abs($all_buy_orders->[0]{amount}) < 1e-8;
        }
        $order_pairs[-1]{profit_usd}   = $order_pairs[-1]{buy}{amount} *
            ($order_pairs[-1]{sell}{net_price_usd} - $order_pairs[-1]{buy}{net_price_usd});
    } # CREATE

    \@order_pairs;
}

sub create_order_pairs {
    my ($pkg, %args) = @_;

    my $r = $args{r};
    my $dbh = $r->{_stash}{dbh};

    #my $accbals = App::cryp::arbit::_get_account_balances($r);

    my @order_pairs;

  COIN:
    for my $coin (@{ $r->{_stash}{coins} }) {
        log_info "Listing orderbooks for coin %s ...", $coin;

        my %sell_orders; # key = exchange safename
        my %buy_orders ; # key = exchange safename

        # the final merged order book. each entry will be a hashref containing
        # these keys:
        #
        # - currency (fiat currency, e.g. USD or IDR)
        #
        # - gross_price_orig (ask/bid price in original base currency)
        #
        # - gross_price_usd (gross price after converted to USD, will be the
        #   same as gross_price_orig if currency=USD)
        #
        # - net_price_orig (net price after adding [if sell order, because we'll
        #   be buying these] or subtracting [if buy order, because we'll be
        #   selling these] trading fee from the original ask/bid price. in
        #   original base currency)
        #
        # - net_price_orig (net_price_orig converted to USD)
        #
        # - exchange (exchange safename)

        my @all_buy_orders;
        my @all_sell_orders;

        # produce final merged order book.
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

                my $buy_fee_pct = App::cryp::arbit::_get_trading_fee(
                    $r, $exchange, $coin);
                for (@{ $res->[2]{buy} }) {
                    push @{ $buy_orders{$exchange} }, {
                        currency         => $cur2,
                        gross_price_orig => $_->[0],
                        net_price_orig   => $_->[0]*(1-$buy_fee_pct/100),
                        amount           => $_->[1],
                    };
                }

                my $sell_fee_pct = App::cryp::arbit::_get_trading_fee(
                    $r, $exchange, $coin);
                for (@{ $res->[2]{sell} }) {
                    push @{ $sell_orders{$exchange} }, {
                        currency         => $cur2,
                        gross_price_orig => $_->[0],
                        net_price_orig   => $_->[0]*(1+$sell_fee_pct/100),
                        amount           => $_->[1],
                    };
                }

                if ($cur2 eq 'USD') {
                    for (@{ $buy_orders{$exchange} }, @{ $sell_orders{$exchange} }) {
                        $_->{gross_price_usd} = $_->{gross_price_orig};
                        $_->{net_price_usd}   = $_->{net_price_orig};
                    }
                } else {
                    # convert fiat to USD
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

                    #log_trace "Will be using these conversion rates from %s to USD: buy=%.4f, sell=%.4f",
                    #    $cur2, $fxrate_buy, $fxrate_sell;

                    # since we will be selling the coins to these buyers, we
                    # will be getting (non-USD, e.g. IDR) fiat currencies. to
                    # exchange these IDR for USD, we need to use the sell
                    # fxrate.
                    for (@{ $buy_orders{$exchange} }) {
                        $_->{gross_price_usd} = $_->{gross_price_orig} * $fxrate_sell;
                        $_->{net_price_usd}   = $_->{net_price_orig}   * $fxrate_sell;
                    }

                    # similary, since we will be buying coins from these
                    # sellers, we will be needing (non-USD, e.g. IDR) fiat
                    # currencies. we will need to sell our USD first to get IDR.
                    # thus, we're using the buy fxrate.
                    for (@{ $sell_orders{$exchange} }) {
                        $_->{gross_price_usd} = $_->{gross_price_orig} * $fxrate_buy;
                        $_->{net_price_usd}   = $_->{net_price_orig}   * $fxrate_buy;
                    }

                } # convert fiat currency

                $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                         $time, $coin, "USD", $buy_orders{$exchange}[0]{gross_price_usd}, $eid, "buy");
                $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                         $time, $coin, "USD", $sell_orders{$exchange}[0]{gross_price_usd}, $eid, "sell");
                unless ($cur2 eq 'USD') {
                    $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                             $time, $coin, $cur2, $buy_orders{$exchange}[0]{gross_price_orig}, $eid, "buy");
                    $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                             $time, $coin, $cur2, $sell_orders{$exchange}[0]{gross_price_orig}, $eid, "sell");
                }
            } # for pair
        } # for exchange

        if (keys(%buy_orders) < 2) {
            log_info "There are less than two exchanges that offer buys for %s, ".
                "skipping this coin";
            next COIN;
        }
        if (keys(%sell_orders) < 2) {
            log_debug "There are less than two exchanges that offer asks for %s, skipping this round";
            next CURRENCY;
        }

        # merge all buys from all exchanges, sort from highest net price
        for my $exchange (keys %buy_orders) {
            for (@{ $buy_orders{$exchange} }) {
                $_->{exchange} = $exchange;
                push @all_buy_orders, $_;
            }
        }
        @all_buy_orders = sort { $b->{net_price_usd} <=> $a->{net_price_usd} }
            @all_buy_orders;

        # merge all sells from all exchanges, sort from lowest price
        for my $exchange (keys %sell_orders) {
            for (@{ $sell_orders{$exchange} }) {
                $_->{exchange} = $exchange;
                push @all_sell_orders, $_;
            }
        }
        @all_sell_orders = sort { $a->{net_price_usd} <=> $b->{net_price_usd} }
            @all_sell_orders;

        log_trace "all_buy_orders  for %s: %s", $coin, \@all_buy_orders;
        log_trace "all_sell_orders for %s: %s", $coin, \@all_sell_orders;

        my $coin_order_pairs = _create_order_pairs(
            coin => $coin,
            all_buy_orders => \@all_buy_orders,
            all_sell_orders => \@all_sell_orders,
            min_profit_pct => $args{min_profit_pct},
            max_orders_amount_per_round => $r->{_cryp}{arbit_strategies}{merge_order_book}{max_orders_amount_per_round},
            max_order_pairs_per_round   => $r->{_cryp}{arbit_strategies}{merge_order_book}{max_order_pairs_per_round},
        );
        push @order_pairs, @$coin_order_pairs;
    } # for coin

    [200, "OK", \@order_pairs];
}

1;
# ABSTRACT: Using merged order books for arbitration

=for Pod::Coverage ^(.+)$

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

The minimum profit percentage is I<min_profit_pct>. We create buy/sell order
pairs starting from the topmost of the merged order book, until we can't get
I<min_profit_pct> anymore.

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


=head1 CONFIGURATION

You can put these configuration under the [arbit-strategies/merge_order_book]
section:

=item * max_orders_amount_per_round

Number, in USD. The total amount of order pairs per order book matching. Note
that this amount is on a per-coin basis. Also, only the selling amounts are
totaled. Default is unlimited.

=item * max_order_pairs_per_round

Number. Default is unlimited.

=back


=head1 SEE ALSO

L<App::cryp::arbit>

Other C<App::cryp::arbit::Strategy::*> modules.
