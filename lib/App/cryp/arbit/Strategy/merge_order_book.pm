package App::cryp::arbit::Strategy::merge_order_book;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::cryp::arbit;
use Finance::Currency::FiatX;
use List::Util qw(min max);
use Storable qw(dclone);

use Role::Tiny::With;

with 'App::cryp::Role::ArbitStrategy';

sub _calculate_order_pairs_for_base_currency {
    my %args = @_;

    my $base_currency         = $args{base_currency};
    my $all_buy_orders        = $args{all_buy_orders};
    my $all_sell_orders       = $args{all_sell_orders};
    my $min_profit_pct        = $args{min_profit_pct} // 0;
    my $max_order_quote_size  = $args{max_order_quote_size};
    my $max_order_pairs       = $args{max_order_pairs};
    my $max_order_size_as_book_item_size_pct = $args{max_order_size_as_book_item_size_pct} // 100;
    my $account_balances      = $args{account_balances};
    my $min_account_balances  = $args{min_account_balances};
    my $exchange_pairs        = $args{exchange_pairs};

    my @order_pairs;

    for (@{ $all_buy_orders }, @{ $all_sell_orders }) {
        $_->{base_size} *= $max_order_size_as_book_item_size_pct/100;
    }

    if ($account_balances && $min_account_balances) {
        for my $e (keys %$account_balances) {
            my $balances = $account_balances->{$e};
            for my $cur (keys %$balances) {
                my $curbalances = $balances->{$cur};
                for my $rec (@$curbalances) {
                    my $eacc = "$e/$rec->{account}";
                    if (defined $min_account_balances->{$eacc} &&
                            defined $min_account_balances->{$eacc}{$cur}) {
                        $rec->{available} -= $min_account_balances->{$eacc}{$cur};
                    }
                }
            }
        }
        App::cryp::arbit::_sort_account_balances($account_balances);
    }

  CREATE:
    while (1) {
        last CREATE if defined $max_order_pairs &&
            @order_pairs >= $max_order_pairs;

        my ($sell, $sell_index);
      FIND_BUYER:
        {
            $sell_index = 0;
            while ($sell_index < @$all_buy_orders) {
                $sell = $all_buy_orders->[$sell_index];
                if ($account_balances) {
                    # we don't have any inventory left to sell on this selling
                    # exchange
                    unless (@{ $account_balances->{ $sell->{exchange} }{$base_currency} }) {
                        $sell_index++; next;
                    }
                }
                last;
            }
            # there are no more buyers left we can sell to
            last CREATE unless $sell_index < @$all_buy_orders;
        }

        my ($buy, $buy_index);
      FIND_SELLER:
        {
            $buy_index = 0;
            while ($buy_index < @$all_sell_orders) {
                $buy = $all_sell_orders->[$buy_index];
                # shouldn't happen though
                if ($buy->{exchange} eq $sell->{exchange}) {
                    $buy_index++; next;
                }
                if ($account_balances) {
                    # we don't have any inventory left to buy from this exchange
                    unless (@{ $account_balances->{ $buy->{exchange} }{$buy->{quote_currency}} }) {
                        $buy_index++; next;
                    }
                }
                last;
            }
            # there are no more sellers left we can buy from
            last CREATE unless $buy_index < @$all_sell_orders;
        }

        my $smaller_price = min($sell->{net_price}, $buy->{net_price});
        my $profit_pct    = ($sell->{net_price} - $buy->{net_price}) /
            $smaller_price * 100;
        if ($profit_pct < $min_profit_pct) {
            log_trace "Ending matching buy->sell because profit percentage is too low (%.4f, wants >= %.4f)",
                $profit_pct, $min_profit_pct;
            last CREATE;
        }

        my $order_pair = {
            sell => {
                exchange         => $sell->{exchange},
                pair             => "$base_currency/$sell->{quote_currency}",
                gross_price_orig => $sell->{gross_price_orig},
                gross_price      => $sell->{gross_price},
                net_price_orig   => $sell->{net_price_orig},
                net_price        => $sell->{net_price},
            },
            buy => {
                exchange         => $buy->{exchange},
                pair             => "$base_currency/$buy->{quote_currency}",
                gross_price_orig => $buy->{gross_price_orig},
                gross_price      => $buy->{gross_price},
                net_price_orig   => $buy->{net_price_orig},
                net_price        => $buy->{net_price},
            },
            profit_pct => $profit_pct,
        };

        if ($account_balances) {
            $order_pair->{sell}{account} = $account_balances->{ $sell->{exchange} }{$base_currency}[0]{account};
            $order_pair->{buy}{account}  = $account_balances->{ $buy ->{exchange} }{$buy->{quote_currency}}[0]{account};
        }

        # limit maximum size of order
        my @sizes = (
            {which => 'buy order' , size => $sell->{base_size}},
            {which => 'sell order', size => $buy ->{base_size}},
        );
        if (defined $max_order_quote_size) {
            push @sizes, (
                {which => 'max_order_quote_size', size => $max_order_quote_size / max($sell->{gross_price}, $buy->{gross_price})},
            );
        }
        if ($account_balances) {
            push @sizes, (
                {
                    which => 'sell exchange balance',
                    size => $account_balances->{ $sell->{exchange} }{$base_currency}[0]{available},
                },
                {
                    which => 'buy exchange balance',
                    size => $account_balances->{ $buy ->{exchange} }{$buy->{quote_currency}}[0]{available}
                        / $buy->{gross_price_orig},
                },
            );
        }
        @sizes = sort { $a->{size} <=> $b->{size} } @sizes;
        my $order_size = $sizes[0]{size};

        $order_pair->{base_size} = $order_size;
        $order_pair->{profit}   = $order_size *
            ($order_pair->{sell}{net_price} - $order_pair->{buy}{net_price});

      UPDATE_INVENTORY_BALANCES:
        for my $i (0..$#sizes) {
            my $size  = $sizes[$i]{size};
            my $which = $sizes[$i]{which};
            my $used_up = $size - $order_size <= 1e-8;
            if ($which eq 'buy order') {
                if ($used_up) {
                    splice @$all_buy_orders, $sell_index, 1;
                } else {
                    $all_buy_orders->[$sell_index]{base_size} -= $order_size;
                }
            } elsif ($which eq 'sell order') {
                if ($used_up) {
                    splice @$all_sell_orders, $buy_index, 1;
                } else {
                    $all_sell_orders->[$buy_index]{base_size} -= $order_size;
                }
            } elsif ($which eq 'sell exchange balance') {
                if ($used_up) {
                    shift @{ $account_balances->{ $sell->{exchange} }{$base_currency} };
                } else {
                    $account_balances->{ $sell->{exchange} }{$base_currency}[0]{available} -=
                        $order_size;
                }
            } elsif ($which eq 'buy exchange balance') {
                my $c = $buy->{quote_currency};
                if ($used_up) {
                    shift @{ $account_balances->{ $buy->{exchange} }{$c} };
                } else {
                    $account_balances->{ $buy->{exchange} }{$c}[0]{available} -=
                        $order_size * $buy->{gross_price_orig};
                }
            }
        } # UPDATE_INVENTORY_BALANCES

        if ($account_balances) {
            App::cryp::arbit::_sort_account_balances($account_balances);
        }

      CHECK_MINIMUM_BUY_SIZE:
        {
            last unless $exchange_pairs;
            my $pair_recs = $exchange_pairs->{ $buy->{exchange} };
            last unless $pair_recs;
            my $pair_rec;
            for (@$pair_recs) {
                if ($_->{base_currency} eq $base_currency) {
                    $pair_rec = $_; last;
                }
            }
            last unless $pair_rec;
            if (defined($pair_rec->{min_base_size}) && $order_pair->{base_size} < $pair_rec->{min_base_size}) {
                #log_trace "buy order base size is too small (%.4f < %.4f), skipping this order pair: %s",
                #    $order_pair->{base_size}, $pair_rec->{min_base_size}, $order_pair;
                next CREATE;
            }
            my $quote_size = $order_pair->{base_size}*$buy->{gross_price_orig};
            if (defined($pair_rec->{min_quote_size}) && $quote_size < $pair_rec->{min_quote_size}) {
                #log_trace "buy order quote size is too small (%.4f < %.4f), skipping this order pair: %s",
                #    $quote_size, $pair_rec->{min_quote_size}, $order_pair;
                next CREATE;
            }
        } # CHECK_MINIMUM_BUY_SIZE

      CHECK_MINIMUM_SELL_SIZE:
        {
            last unless $exchange_pairs;
            my $pair_recs = $exchange_pairs->{ $sell->{exchange} };
            last unless $pair_recs;
            my $pair_rec;
            for (@$pair_recs) {
                if ($_->{base_currency} eq $base_currency) {
                    $pair_rec = $_; last;
                }
            }
            last unless $pair_rec;
            if (defined $pair_rec->{min_base_size} && $order_pair->{base_size} < $pair_rec->{min_base_size}) {
                #log_trace "sell order base size is too small (%.4f < %.4f), skipping this order pair: %s",
                #    $order_pair->{base_size}, $pair_rec->{min_base_size}, $order_pair;
                next CREATE;
            }
            my $quote_size = $order_pair->{base_size}*$sell->{gross_price_orig};
            if (defined $pair_rec->{min_quote_size} && $quote_size < $pair_rec->{min_quote_size}) {
                #log_trace "sell order quote size is too small (%.4f < %.4f), skipping this order pair: %s",
                #    $quote_size, $pair_rec->{min_quote_size}, $order_pair;
                next CREATE;
            }
        } # CHECK_MINIMUM_SELL_SIZE

        push @order_pairs, $order_pair;

    } # CREATE

    \@order_pairs;
}

sub calculate_order_pairs {
    my ($pkg, %args) = @_;

    my $r = $args{r};
    my $dbh = $r->{_stash}{dbh};

    my @order_pairs;

  GET_ACCOUNT_BALANCES:
    {
        last if $r->{args}{ignore_balance};
        App::cryp::arbit::_get_account_balances($r, 'no-cache');
    } # GET_ACCOUNT_BALANCES

    my %exchanges_for; # key="base currency"/"quote cryptocurrency or ':fiat'", value => [exchange, ...]
    my %fiat_for;      # key=exchange safename, val=[fiat currency, ...]
    my %pairs_for;     # key=exchange safename, val=[pair, ...]
  DETERMINE_SETS:
    for my $exchange (sort keys %{ $r->{_stash}{exchange_clients} }) {
        my $pair_recs = $r->{_stash}{exchange_pairs}{$exchange};
        for my $pair_rec (@$pair_recs) {
            my $pair = $pair_rec->{name};
            my ($basecur, $quotecur) = $pair =~ m!(.+)/(.+)!;
            next unless grep { $_ eq $basecur  } @{ $r->{_stash}{base_currencies}  };
            next unless grep { $_ eq $quotecur } @{ $r->{_stash}{quote_currencies} };

            my $key;
            if (App::cryp::arbit::_is_fiat($quotecur)) {
                $key = "$basecur/:fiat";
                $fiat_for{$exchange} //= [];
                push @{ $fiat_for{$exchange} }, $quotecur
                    unless grep { $_ eq $quotecur } @{ $fiat_for{$exchange} };
            } else {
                $key = "$basecur/$quotecur";
            }
            $exchanges_for{$key} //= [];
            push @{ $exchanges_for{$key} }, $exchange;

            $pairs_for{$exchange} //= [];
            push @{ $pairs_for{$exchange} }, $pair
                unless grep { $_ eq $pair } @{ $pairs_for{$exchange} };
        }
    } # DETERMINE_SETS

    # since we're doing N sets, split the balance fairly for each set
    my $account_balances = dclone($r->{_stash}{account_balances});
    my $num_sets = keys %exchanges_for;
    for my $e (keys %$account_balances) {
        my $balances = $account_balances->{$e};
        for my $cur (keys %$balances) {
            my $recs = $balances->{$cur};
            for my $rec (@$recs) {
                $rec->{available} /= $num_sets;
            }
        }
    }

  SET:
    for my $set (sort keys %exchanges_for) {
        my ($base_currency, $quote_currency0) = $set =~ m!(.+)/(.+)!;

        my %sell_orders; # key = exchange safename
        my %buy_orders ; # key = exchange safename

        # the final merged order book. each entry will be a hashref containing
        # these keys:
        #
        # - currency (the base/target currency to arbitrage)
        #
        # - gross_price_orig (ask/bid price in exchange's original quote
        #   currency)
        #
        # - gross_price (like gross_price_orig, but price will be converted to
        #   USD if quote currency is fiat)
        #
        # - net_price_orig (net price after adding [if sell order, because we'll
        #   be buying these] or subtracting [if buy order, because we'll be
        #   selling these] trading fee from the original ask/bid price. in
        #   exchange's original quote currency)
        #
        # - net_price (like net_price_orig, but price will be converted to USD
        #   if quote currency is fiat)
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

            my @pairs;
            if ($quote_currency0 eq ':fiat') {
                push @pairs, map { "$base_currency/$_" } @{ $fiat_for{$exchange} };
            } else {
                push @pairs, $set;
            }

          PAIR:
            for my $pair (@pairs) {
                my ($basecur, $quotecur) = split m!/!, $pair;
                next unless grep { $_ eq $pair } @{ $pairs_for{$exchange} };

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
                    $r, $exchange, $base_currency);
                for (@{ $res->[2]{buy} }) {
                    push @{ $buy_orders{$exchange} }, {
                        quote_currency   => $quotecur,
                        gross_price_orig => $_->[0],
                        net_price_orig   => $_->[0]*(1-$buy_fee_pct/100),
                        base_size        => $_->[1],
                    };
                }

                my $sell_fee_pct = App::cryp::arbit::_get_trading_fee(
                    $r, $exchange, $base_currency);
                for (@{ $res->[2]{sell} }) {
                    push @{ $sell_orders{$exchange} }, {
                        quote_currency   => $quotecur,
                        gross_price_orig => $_->[0],
                        net_price_orig   => $_->[0]*(1+$sell_fee_pct/100),
                        base_size        => $_->[1],
                    };
                }

                if (!App::cryp::arbit::_is_fiat($quotecur) || $quotecur eq 'USD') {
                    for (@{ $buy_orders{$exchange} }, @{ $sell_orders{$exchange} }) {
                        $_->{gross_price} = $_->{gross_price_orig};
                        $_->{net_price}   = $_->{net_price_orig};
                    }
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                             $time, $base_currency, $quotecur, $buy_orders{$exchange}[0]{gross_price_orig}, $eid, "buy");
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                             $time, $base_currency, $quotecur, $sell_orders{$exchange}[0]{gross_price_orig}, $eid, "sell");
                } else {
                    # convert fiat to USD
                    my ($fxrate_buy, $fxrate_sell);

                    my $cbuyres  = Finance::Currency::FiatX::convert_fiat_currency(
                        amount => 1, from => $quotecur, to => 'USD', dbh => $dbh, type => 'buy');
                    if ($cbuyres->[0] != 200) {
                        log_error "Couldn't get conversion rate (buy) from %s to USD, skipping this pair",
                            $quotecur;
                        next PAIR;
                    }
                    $fxrate_buy = $cbuyres->[2];

                    my $csellres = Finance::Currency::FiatX::convert_fiat_currency(
                        amount => 1, from => $quotecur, to => 'USD', dbh => $dbh, type => 'sell');
                    if ($csellres->[0] != 200) {
                        log_error "Couldn't get conversion rate (sell) from %s to USD, skipping this pair",
                            $quotecur;
                        next PAIR;
                    }
                    $fxrate_sell = $csellres->[2];

                    #log_trace "Will be using these conversion rates from %s to USD: buy=%.4f, sell=%.4f",
                    #    $quotecur, $fxrate_buy, $fxrate_sell;

                    # since we will be selling the coins to these buyers, we
                    # will be getting (non-USD, e.g. IDR) fiat currencies. to
                    # exchange these IDR for USD, we need to use the sell
                    # fxrate.
                    for (@{ $buy_orders{$exchange} }) {
                        $_->{gross_price} = $_->{gross_price_orig} * $fxrate_sell;
                        $_->{net_price}   = $_->{net_price_orig}   * $fxrate_sell;
                    }

                    # similary, since we will be buying coins from these
                    # sellers, we will be needing (non-USD, e.g. IDR) fiat
                    # currencies. we will need to sell our USD first to get IDR.
                    # thus, we're using the buy fxrate.
                    for (@{ $sell_orders{$exchange} }) {
                        $_->{gross_price} = $_->{gross_price_orig} * $fxrate_buy;
                        $_->{net_price}   = $_->{net_price_orig}   * $fxrate_buy;
                    }

                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                             $time, $base_currency, $quotecur, $buy_orders{$exchange}[0]{gross_price_orig}, $eid, "buy");
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                         $time, $base_currency, $quotecur, $sell_orders{$exchange}[0]{gross_price_orig}, $eid, "sell");
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                             $time, $base_currency, "USD", $buy_orders{$exchange}[0]{gross_price}, $eid, "buy");
                    $dbh->do("INSERT INTO price (time,base_currency,quote_currency,price,exchange_id,type) VALUES (?,?,?,?,?,?)", {},
                         $time, $base_currency, "USD", $sell_orders{$exchange}[0]{gross_price}, $eid, "sell");

                } # convert fiat currency to USD
            } # for pair
        } # for exchange

        # sanity checks
        if (keys(%buy_orders) < 2) {
            log_info "There are less than two exchanges that buy %s, ".
                "skipping this base currency";
            next SET;
        }
        if (keys(%sell_orders) < 2) {
            log_debug "There are less than two exchanges that sell %s, skipping this base currency",
                $base_currency;
            next SET;
        }

        # merge all buys from all exchanges, sort from highest net price
        for my $exchange (keys %buy_orders) {
            for (@{ $buy_orders{$exchange} }) {
                $_->{exchange} = $exchange;
                push @all_buy_orders, $_;
            }
        }
        @all_buy_orders = sort { $b->{net_price} <=> $a->{net_price} }
            @all_buy_orders;

        # merge all sells from all exchanges, sort from lowest price
        for my $exchange (keys %sell_orders) {
            for (@{ $sell_orders{$exchange} }) {
                $_->{exchange} = $exchange;
                push @all_sell_orders, $_;
            }
        }
        @all_sell_orders = sort { $a->{net_price} <=> $b->{net_price} }
            @all_sell_orders;

        #log_trace "all_buy_orders  for %s: %s", $base_currency, \@all_buy_orders;
        #log_trace "all_sell_orders for %s: %s", $base_currency, \@all_sell_orders;

        my $coin_order_pairs = _calculate_order_pairs_for_base_currency(
            base_currency => $base_currency,
            all_buy_orders => \@all_buy_orders,
            all_sell_orders => \@all_sell_orders,
            min_profit_pct => $r->{args}{min_profit_pct},
            max_order_quote_size => $r->{args}{max_order_quote_size},
            max_order_size_as_book_item_size_pct => $r->{_cryp}{arbit_strategies}{merge_order_book}{max_order_size_as_book_item_size_pct},
            max_order_pairs      => $r->{args}{max_order_pairs_per_round},
            (account_balances    => $account_balances) x !$r->{args}{ignore_balance},
            min_account_balances => $r->{args}{min_account_balances},
            (exchange_pairs       => $r->{_stash}{exchange_pairs}) x !$r->{args}{ignore_min_order_size}
        );
        for (@$coin_order_pairs) {
            $_->{base_currency} = $base_currency;
        }
        push @order_pairs, @$coin_order_pairs;
    } # for set (base currency)

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

=item * max_order_size_as_book_item_size_pct

Number 0-100. Default is 100. This setting is used for more safety since order
books are rapidly changing. For example, there is an item in the merged order
book as follows:

 type  exchange   price  amount   item#
 ----  --------   -----  ------   -----
 buy   exchange1  800.1  12       B1
 buy   exchange1  798.1  24       B2
 ...
 sell  exchange2  780.1   5       S1
 sell  exchange2  782.9   8       S2
 ...

If `max_order_size_as_book_item_size_pct` is set to 100, then this will create
order pairs as follows:

 size  buy from   buy price  sell to    sell price  item#
 ----  --------   ---------  -------    ----------  -----
 5     exchange2  780.1      exchange1  800.1       OP1
 7     exchange2  782.9      exchange1  800.1       OP2
 ...

The OP1 will use up (100%) of item #S1 from the order book, then OP2 will use up
(100%) item #B1 from the order book.

However, if `max_order_size_as_book_item_size_pct` is set to 75, then this will
create order pairs as follows:

 size  buy from   buy price  sell to    sell price  item#
 ----  --------   ---------  -------    ----------  -----
 3.75  exchange2  780.1      exchange1  800.1       OP1
 5.25  exchange2  782.9      exchange1  800.1       OP2

OP1 will use 75% item S1 from the order book, then the strategy will move on to
the next sell order (S2). OP2 will also use only 75% of item B1 (3.75 + 5.25 =
9, which is 75% of 12) before moving on to the next buy order.

=back


=head1 SEE ALSO

L<App::cryp::arbit>

Other C<App::cryp::arbit::Strategy::*> modules.
