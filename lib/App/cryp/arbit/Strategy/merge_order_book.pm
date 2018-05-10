package App::cryp::arbit::Strategy::merge_order_book;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

with 'App::cryp::Role::ArbitStrategy';

sub create_order_pairs {
    my %args = @_;

    my $res;







    sub _check_prices {
    my $r = shift;

    my $dbh = $r->{_dbh};

    _update_exchange_rates($r);

    my @currencies = ("BTC", "BCH", "LTC", "ETH"); # XXX currently hardcoded
  CURRENCY:
    for my $c (@currencies) {
        my %prices; # key = exchange_id, val = price in USD
        my %vols  ; # key = exchange_id, val = volume in USD

        my %asks; # key = exchange_id, val = [[lowest-price-in-USD , amount-of-currency], [2nd-lowest-price-in-USD , amount-of-currency], ...]
        my %bids; # key = exchange_id, val = [[highest-price-in-USD, amount-of-currency], [2nd-highest-price-in-USD, amount-of-currency], ...]

        # XXX hardcoded for now
        my %fees_pct; # key = exchange_id, val = market taker fees
        $fees_pct{$r->{_eid_gdax}}  = $c eq 'BTC' ? 0.25 : 0.3;
        $fees_pct{$r->{_eid_btcid}} = 0.3;

      CHECK_GDAX:
        {
            my $time;

            $time = time();
            log_trace "Checking $c-USD order book on GDAX ...";
            my $res = $r->{_gdaxlite}->public_request(
                GET => "/products/$c-USD/book?level=2",
            );
            unless ($res->[0] == 200) {
                log_error "Couldn't get $c-USD order book on GDAX: $res->[0] - $res->[1], skipping GDAX";
                last CHECK_GDAX;
            }
            # log_trace "$c-USD order book on GDAX: %s", $res->[2]; # too much info to log
            for (@{ $res->[2]{asks} }, @{ $res->[2]{bids} }) {
                $_->[1] *= $_->[2];
                splice @$_, 2;
            }

            # sanity checks
            unless (@{ $res->[2]{asks} }) {
                log_warn "No asks for $c-USD on GDAX, skipping GDAX";
                last CHECK_GDAX;
            }
            unless (@{ $res->[2]{bids} }) {
                log_warn "No bids for $c-USD on GDAX, skipping GDAX";
                last CHECK_GDAX;
            }

            $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id) VALUES (?,?,?,?,?)", {},
                     $time, $c, "USD", $res->[2]{asks}[0], $r->{_eid_gdax},
                 );
            $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id) VALUES (?,?,?,?,?)", {},
                     $time, "USD", $c, $res->[2]{bids}[0], $r->{_eid_gdax},
                 );

            $asks{$r->{_eid_gdax}} = $res->[2]{asks};
            $bids{$r->{_eid_gdax}} = $res->[2]{bids};

        } # CHECK_GDAX

      CHECK_BTCID:
        {
            my $time;

            $time = time();
            log_trace "Getting $c-IDR order book on BTCID ...";
            my $res;
            eval { $res = $r->{_btcid}->get_depth(pair => lc($c)."_idr") };
            if ($@) {
                log_error "Died when getting $c-IDR order book on BTCID: $@, skipping BTCID";
                last CHECK_BTCID;
            }
            unless ($res->[0] == 200) {
                log_error "Couldn't get $c-IDR order book on BTCID: $res->[0] - $res->[1], skipping BTCID";
                last CHECK_BTCID;
            }
            # log_trace "$c-IDR order book on BTCID: %s", $res->[2]; # too much info to log

            # convert all fiat prices to USD
            for (@{ $res->[2]{sell} }, @{ $res->[2] }{buy}) {
                $_->[0] *= $r->{_fxrates}{IDR_USD};
            }

            # sanity checks
            unless (@{ $res->[2]{sell} }) {
                log_warn "No asks for $c-IDR on BTCID, skipping BTCID";
                last CHECK_BTCID;
            }
            unless (@{ $res->[2]{buy} }) {
                log_warn "No bids for $c-IDR on BTCID, skipping BTCID";
                last CHECK_BTCID;
            }

            $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id) VALUES (?,?,?,?,?)", {},
                     $time, $c, "USD", $res->[2]{sell}[0], $r->{_eid_btcid},
                 );
            $dbh->do("INSERT INTO price (time,currency1,currency2,price,exchange_id) VALUES (?,?,?,?,?)", {},
                     $time, "USD", $c, $res->[2]{buy}[0], $r->{_eid_btcid},
                 );

            $asks{$r->{_eid_btcid}} = $res->[2]{sell};
            $bids{$r->{_eid_btcid}} = $res->[2]{buy};

        } # CHECK_BTCID

        if (keys(%bids) < 2) {
            log_debug "There are less than two exchanges that offer bids for $c-USD, skipping this round";
            next CURRENCY;
        }
        if (keys(%asks) < 2) {
            log_debug "There are less than two exchanges that offer asks for $c-USD, skipping this round";
            next CURRENCY;
        }

        # XXX dummy, use real balances
        my %balances_cur; # key = exchange id, value = amount of currency
        my %balances_usd; # key = exchange id, value = amount of USD
        %balances_cur = (
            $r-{_eid_gdax}  => 999999999,
            $r-{_eid_btcid} => 999999999,
        );
        %balances_usd = (
            $r-{_eid_gdax}  => 999999999,
            $r-{_eid_btcid} => 999999999,
        );

        # merge all bids from all exchanges, sort from highest price
        my @all_bids;
        for my $eid (keys %bids) {
            for my $item (@{ $bids{$eid} }) {
                push @all_bids, [$eid, @$item];
            }
        }
        @all_bids = sort { $b->[1] <=> $a->[1] } @all_bids;

        # merge all asks from all exchanges, sort from lowest price
        my @all_asks;
        for my $eid (keys %asks) {
            for my $item (@{ $asks{$eid} }) {
                push @all_asks, [$eid, @$item];
            }
        }
        @all_asks = sort { $a->[1] <=> $b->[1] } @all_asks;

        my $num_order_pairs;
      ARBITRAGE:
        {
            last unless @all_bids;

            # let's take a look at the highest bidder that we can sell to
            my $eid_bid = $all_bids[0][0];
            my $p_bid   = $all_bids[0][1];
            my $amount_bid_cur = $all_bids[0][2];
            my $amount_bid_usd = $amount_bid_cur * $p_bid;
            # after subtracted by fees,
            my $nett_p_bid = $p_bid * (1 - $fees_pct{$eid_bid}/100);

            last unless @all_asks;
            my $i2 = 0;
            while ($i2 < @all_asks) {
                my $eid2 = $all_asks[$i2][0];
                if ($eid1 == $eid2) {
                    $i2++; next;
                }
                my $p2 = $all_asks[$i2][1];
                my $amount2_cur = $all_asks[$i2][2];
                my $amount2_usd = $amount2_cur * $p2;
                my $nett_p2 = (1-$p2 * (1 + $fees_pct{$eid1}/100);

                # check if selling X currency at p1 on E1 while buying X
                # currency at p2 is profitable enough
                my $nett_p_smaller = $nett_p1 < $nett_p2 ? $nett_p1 : $nett_p2;
                my $nett_pdiff_pct = ($nett_p1 - $nett_p2) / $nett_p_smaller * 100;

                if ($net_pdiff_pct <= $r->{args}{min_price_difference_percentage}) {
                    last ARBITRAGE;
                }

                my $balance1_cur = $balances_cur{$eid1};
                my $balance2_usd = $balances_usd{$eid2};

                # first, pick the lesser of the amount
                my $amount_cur = $amount1_cur <= $amount2_cur ? $amount1_cur : $amount2_cur;

                # second, reduce if selling balance doesn't suffice
                if ($balances_cur{$eid1} < $amount_cur) {
                    $amount_cur = $balances_cur{$eid1};
                }
                if ($balances_usd{$eid1} < $amount_cur * $nett_p2) {

                }

                log_trace "Would net profit %.3f%% by selling %s on %s at %.3f USD ".
                    "and buying on %s at %.3f USD",
                    $nett_pdiff_pct, $c,
                    $r->{_exchanges}{$eid1}, $p1,
                    $r->{_exchanges}{$eid2}, $p2,
                    ;

            }
        } # ARBITRAGE

    } # for currency

    [200];
}
}







    $res;
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
