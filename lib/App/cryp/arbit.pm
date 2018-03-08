package App::cryp::arbit;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Devel::Confess;
use Log::ger;

use Time::HiRes qw(time);

our %SPEC;

$SPEC{':package'} = {
    summary => 'A cryptocurrency arbitrage script',
    v => 1.1,
};

our %args_db = (
    db_name => {
        schema => 'str*',
        req => 1,
        tags => ['category:database-connection'],
    },
    # XXX db_host
    # XXX db_port
    db_username => {
        schema => 'str*',
        tags => ['category:database-connection'],
    },
    db_password => {
        schema => 'str*',
        tags => ['category:database-connection'],
    },
);

our $db_schema_spec = {
    latest_v => 1,
    install => [
        'CREATE TABLE exchange (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             shortname VARCHAR(8) NOT NULL, UNIQUE(shortname),
             safename VARCHAR(100) NOT NULL, UNIQUE(safename)
         )',
        'CREATE TABLE account (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             ctime DOUBLE NOT NULL,
             exchange_id INT NOT NULL,
             note VARCHAR(255)
         )',
        'CREATE TABLE price (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL, INDEX(time),
             currency1 VARCHAR(10) NOT NULL,
             currency2 VARCHAR(10) NOT NULL,
             price DECIMAL(21,8) NOT NULL, -- price to buy currency1 in currency2, e.g. currency1 = BTC, currency2 = USD, price = 11150
             exchange_id INT,              -- either set this...
             place VARCHAR(10),            -- ...or fill this e.g. "klikbca"
             note VARCHAR(255)
         )',
        'CREATE TABLE `orderpair` (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             ctime DOUBLE NOT NULL, INDEX(ctime), -- create time in our database

             currency1 VARCHAR(10) NOT NULL, -- the currency we are arbitraging
             currency2 VARCHAR(10) NOT NULL, -- the pair currency (usually fiat, or BTC)

             amount DECIMAL(21,8) NOT NULL, -- amount of currency1 that we are arbitraging (sell on "sell_exchange" and buy on "buy_exchange")

             -- we sell "amount" of "currency1" on "sell_exchange" at "sell_price" (in currency2)
             sell_exchange_id INT NOT NULL,
             sell_exchange_ctime DOUBLE, -- create time in "sell_exchange"
             sell_exchange_order_id VARCHAR(32),
             sell_price DECIMAL(21,8) NOT NULL, -- price of currency1 in currency2 when selling, should be > "buy_price"
             sell_remaining DECIMAL(21,8) NOT NULL,
             sell_order_status VARCHAR(16) NOT NULL,

             -- then buy the same "amount" of "currency1" on "buy_exchange" at "buy_price" (in currency2)
             buy_exchange_id INT NOT NULL,
             buy_exchange_ctime DOUBLE, -- order create time in "buy_exchange"
             buy_exchange_order_id VARCHAR(32),
             buy_price DECIMAL(21,8) NOT NULL, -- price of currency1 in currency2 when buying, should be < "sell_price"
             buy_remaining DECIMAL(21,8) NOT NULL,
             buy_status VARCHAR(16) NOT NULL,

             -- possible statuses: dummy, opening (submitting to exchange), open (created and open), pausing, paused, completing, completed, cancelling, cancelled

             net_profit_pct DOUBLE NOT NULL, -- predicted net profit percentage (after trading fees)

             note VARCHAR(255)
         )',

        # XXX order_log (change of status)
        'CREATE TABLE tx (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL, INDEX(time),
             note VARCHAR(255)
         )',
        'CREATE TABLE profit (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL, INDEX(time),
             currency VARCHAR(10) NOT NULL,
             amount DECIMAL(21,8) NOT NULL,
             note VARCHAR(255)
         )',
        'CREATE TABLE balance (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL, INDEX(time),
             account_id INT NOT NULL,
             currency VARCHAR(10) NOT NULL,
             amount DECIMAL(21,8) NOT NULL,
             note VARCHAR(255)
         )',
        # XXX balance_log (change of balances)
    ],
};

sub _init {
    my $r = shift;

    require DBIx::Connect::MySQL;
    log_trace "Connecting to database ...";
    $r->{_dbh} = DBIx::Connect::MySQL->connect(
        "dbi:mysql:database=$r->{args}{db_name}",
        $r->{args}{db_username},
        $r->{args}{db_password},
        {RaiseError => 1},
    );
    my $dbh = $r->{_dbh};

    require SQL::Schema::Versioned;
    my $res = SQL::Schema::Versioned::create_or_update_db_schema(
        dbh => $r->{_dbh}, spec => $db_schema_spec,
    );
    die "Cannot run the application: cannot create/upgrade database schema: $res->[1]"
        unless $res->[0] == 200;

    # create exchange accounts & API clients
    {
        my $time = time();

        $dbh->do("INSERT IGNORE INTO exchange (shortname,safename) VALUES ('GDAX','gdax')");
        $dbh->do("INSERT IGNORE INTO exchange (shortname,safename) VALUES ('VIP','bitcoin-indonesia')");
        my ($eid_gdax)  = $dbh->selectrow_array("SELECT id FROM exchange WHERE safename='gdax'");
        my ($eid_btcid) = $dbh->selectrow_array("SELECT id FROM exchange WHERE safename='bitcoin-indonesia'");
        $r->{_eid_gdax}  = $eid_gdax;
        $r->{_eid_btcid} = $eid_btcid;

        unless ($r->{_cryp}{exchanges}{gdax}{default}) {
            die "Please specify [exchange/gdax] section in configuration";
        }
        my ($aid_gdax)  = $dbh->selectrow_array("SELECT id FROM account WHERE exchange_id=$eid_gdax  AND note='default'");
        if (!$aid_gdax) {
            $dbh->do("INSERT INTO account (ctime, exchange_id, note) VALUES (?,?,?)", {}, $time, $eid_gdax, 'default');
            ($aid_gdax) = $dbh->selectrow_array("SELECT id FROM account WHERE exchange_id=$eid_gdax  AND note='default'");
            $r->{_aid_gdax}  = $aid_gdax;
        }
        if (!$r->{_gdaxlite}) {
            require Finance::GDAX::Lite;
            $r->{_gdaxlite} = Finance::GDAX::Lite->new(
                key        => $r->{_cryp}{exchanges}{gdax}{default}{key},
                secret     => $r->{_cryp}{exchanges}{gdax}{default}{secret},
                passphrase => $r->{_cryp}{exchanges}{gdax}{default}{passphrase},
            );
        }

        unless ($r->{_cryp}{exchanges}{'bitcoin-indonesia'}{default}) {
            die "Please specify [bitcoin-indonesia/gdax] section in configuration";
        }
        my ($aid_btcid) = $dbh->selectrow_array("SELECT id FROM account WHERE exchange_id=$eid_btcid AND note='default'");
        if (!$aid_btcid) {
            $dbh->do("INSERT INTO account (ctime, exchange_id, note) VALUES (?,?,?)", {}, $time, $eid_btcid, 'default');
            ($aid_btcid) = $dbh->selectrow_array("SELECT id FROM account WHERE exchange_id=$eid_btcid  AND note='default'");
            $r->{_aid_btcid} = $aid_btcid;
        }
        if (!$r->{_btcid}) {
            require Finance::BTCIndo;
            $r->{_btcid} = Finance::BTCIndo->new(
                key        => $r->{_cryp}{exchanges}{'bitcoin-indonesia'}{default}{key},
                secret     => $r->{_cryp}{exchanges}{'bitcoin-indonesia'}{default}{secret},
            );
        }

        my $sth = $dbh->prepare("SELECT id, shortname FROM exchange");
        $sth->execute;
        my %exchanges;
        while (my $row = $sth->fetchrow_hashref) {
            $exchanges{$row->{id}} = $row->{shortname};
        }
        $r->{_exchanges} = \%exchanges;
    }

    [200];
}

sub _update_exchange_rates {
    my $r = shift;

    my $dbh = $r->{_dbh};

    my $time = time();
    my $freq = $r->{args}{check_exchange_rate_frequency};

    my ($time_usd_idr, $price_usd_idr) = $dbh->selectrow_array(
        "SELECT time, price FROM price WHERE time >= ? AND currency1='USD' AND currency2='IDR' ORDER BY time DESC LIMIT 1", {}, $time - $freq);
    my ($time_idr_usd, $price_idr_usd) = $dbh->selectrow_array(
        "SELECT time, price FROM price WHERE time >= ? AND currency1='IDR' AND currency2='USD' ORDER BY time DESC LIMIT 1", {}, $time - $freq);

    my ($old_price_usd_idr) = $dbh->selectrow_array(
        "SELECT time, price FROM price WHERE time >= ? AND currency1='USD' AND currency2='IDR' ORDER BY time DESC LIMIT 1", {}, $time - 3*$freq);
    my ($old_price_idr_usd) = $dbh->selectrow_array(
        "SELECT time, price FROM price WHERE time >= ? AND currency1='IDR' AND currency2='USD' ORDER BY time DESC LIMIT 1", {}, $time - 3*$freq);

  TRY:
    {
        last if $time_usd_idr && $time_usd_idr;

      TRY_KLIKBCA:
        {
            require Finance::Currency::Convert::KlikBCA;
            log_trace "Getting USD-IDR exchange rate from KlikBCA ...";
            my $res = Finance::Currency::Convert::KlikBCA::get_currencies();
            unless ($res->[0] == 200) {
                log_warn "Couldn't get exchange rate from KlikBCA: $res->[0] - $res->[1]";
                last TRY_KLIKBCA;
            }
            my ($x1, $x2) = ($res->[2]{currencies}{USD}{sell_er}, $res->[2]{currencies}{USD}{buy_er});
            if (!$x1 || !$x2) {
                log_warn "sell_er and/or buy_er prices are zero or not found, skipping using KlikBCA prices";
                last TRY_KLIKBCA;
            }
            $price_usd_idr = $x1;
            $price_idr_usd = 1 / $x2;
            $time_idr_usd = $time_usd_idr = $time;

            log_trace "Got prices from KlikBCA: USD/IDR=%.8f, IDR/USD=%.8f", $price_usd_idr, $price_idr_usd;
            $dbh->do("INSERT INTO price (time,currency1,currency2,price,place, note) VALUES (?,?,?,?,?, ?)", {},
                     $time, 'USD', 'IDR', $price_usd_idr, 'KlikBCA',
                     'sell_er',
                 );
            $dbh->do("INSERT INTO price (time,currency1,currency2,price,place, note) VALUES (?,?,?,?,?, ?)", {},
                     $time, 'IDR', 'USD', $price_idr_usd, 'KlikBCA',
                     '1/buy_er',
                 );

            last TRY;
        }

      TRY_GMC:
        {
            require Finance::Currency::Convert::GMC;
            log_trace "Getting USD-IDR exchange rate from GMC ...";
            my $res = Finance::Currency::Convert::GMC::get_currencies();
            unless ($res->[0] == 200) {
                log_warn "Couldn't get exchange rate from GMC: $res->[0] - $res->[1]";
                last TRY_GMC;
            }
            my ($x1, $x2) = ($res->[2]{currencies}{USD}{sell}, $res->[2]{currencies}{USD}{buy});
            if (!$x1 || !$x2) {
                log_warn "sell and/or buy prices are zero or not found, skipping using GMC prices";
                last TRY_GMC;
            }
            $price_usd_idr = $x1;
            $price_idr_usd = 1 / $x2;
            $time_idr_usd = $time_usd_idr = $time;

            log_trace "Got prices from GMC: USD/IDR=%.8f, IDR/USD=%.8f", $price_usd_idr, $price_idr_usd;
            $dbh->do("INSERT INTO price (time,currency1,currency2,price,place, note) VALUES (?,?,?,?,?, ?)", {},
                     $time, 'USD', 'IDR', $price_usd_idr, 'GMC',
                     'sell',
                 );
            $dbh->do("INSERT INTO price (time,currency1,currency2,price,place, note) VALUES (?,?,?,?,?, ?)", {},
                     $time, 'IDR', 'USD', $price_idr_usd, 'GMC',
                     '1/buy',
                 );

            last TRY;
        }

        if ($old_price_idr_usd && $old_price_usd_idr) {
            log_error "Couldn't update exchange rates, continuing with old prices for now";
            $price_usd_idr = $old_price_usd_idr;
            $price_idr_usd = $old_price_idr_usd;
        } else {
            die "Couldn't update exchange rates for a while (or ever), bailing out";
        }
    }

    $r->{_fxrates} = {
        USD_IDR => $price_usd_idr,
        IDR_USD => $price_idr_usd,
    };

    [200];
}

sub _arbitrage {
    my ($r, $bids, $asks) = @_;

}

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
            my $eid1 = $all_bids[0][0];
            my $p1 = $all_bids[0][1];
            my $nett_p1 = $p1 * (1 - $fees_pct{$eid1}/100);

            last unless @all_asks;
            my $i2 = 0;
            while ($i2 < @all_asks) {
                my $eid2 = $all_asks[$i2][0];
                if ($eid1 == $eid2) {
                    $i2++; next;
                }
                my $p2 = $all_asks[$i2][1];
                my $nett_p2 = $p2 * (1 + $fees_pct{$eid1}/100);

                # check if selling X currency at p1 on E1 while buying X
                # currency at p2 is profitable enough
                my $nett_p_smaller = $nett_p1 < $nett_p2 ? $nett_p1 : $nett_p2;
                my $nett_pdiff_pct = ($nett_p1 - $nett_p2) / $nett_p_smaller * 100;

                if ($net_pdiff_pct <= $r->{args}{min_price_difference_percentage}) {
                    last ARBITRAGE;
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

$SPEC{arbit} = {
    v => 1.1,
    summary => 'A cryptocurrency arbitrage script',
    args => {
        %args_db,
        check_prices_frequency => {
            summary => 'How many seconds to wait between checking prices '.
                'at the cryptoexchanges (in seconds)',
            schema => 'posint*',
            default => 30,
            tags => ['category:timing'],
        },
        check_exchange_rate_frequency => {
            summary => 'How long should fiat (e.g. USD to IDR) exchange '.
                'rate be cached (in seconds)',
            schema => 'posint*',
            default => 4*3600,
            tags => ['category:timing'],
        },
        max_order_age => {
            summary => 'How long should we wait for orders to be completed '.
                'before cancelling them (in seconds)',
            schema => 'posint*',
            default => 2*60,
            tags => ['category:timing'],
            descripiton => <<'_',

Sometimes because of rapid trading and price movement, our order might not be
filled immediately. This setting sets a limit on how long should an order be
left open. After this limit is reached, we cancel the order. The imbalance of
the arbitrage transaction will be recorded.

_
        },
        min_price_difference_percentage => {
            summary => 'What minimum percentage of price difference should '.
                'trigger an arbitrage transaction',
            schema => 'float*',
            description => <<'_',

Below this percentage number, price difference will be recorded in the database
but will be ignored (not acted upon). Note that the price difference that will
be considered is the *net* price difference (after subtracted by trading fees).

See also: `order_max_amount`.

_
            tags => ['category:profit-setting'],
        },
        max_order_amount => {
            summary => 'What is the maximum amount of a single order (in USD)',
            schema => 'float*',
            default => 100,
            description => <<'_',

A single order will be limited to not be above this value (in USD). This is the
amount for the selling (because an arbitrage transaction is comprised of a pair
of orders, where one order is a selling order at a higher USD amount than the
buying order).

Note that order amount can also be smaller due to: 1) insufficient demand (when
selling) or supply (when buying) in the order book; 2) insufficient balance of
the inventory.

_
            tags => ['category:trading'],
        },

        #TODO:
        #base_fiat_currency => {
        #    schema => 'currency::code*',
        #    default => 'USD',
        #    tags => ['category:fiat'],
        #},

    },
    features => {
        dry_run => 1,
    },
};
sub arbit {
    my %args = @_;

    my $r = $args{-cmdline_r};

    _init($r);

    while (1) {
        _check_prices($r);
        log_trace "Sleeping %d second(s) ...", $args{check_prices_frequency};
        sleep $args{check_prices_frequency};
    }

    [200]; # should not be reached
}

1;
# ABSTRACT:

=head1 SYNOPSIS

Please see included script L<cryp-arbit>.


=head1 SEE ALSO
