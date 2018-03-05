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
             place VARCHAR(10) NOT NULL,   -- ...or fill this e.g. "klikbca"
             note VARCHAR(255)
         )',
        'CREATE TABLE `order` (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             pair_id INT, INDEX(pair_id), -- orders are created in pairs
             ctime DOUBLE NOT NULL, INDEX(ctime), -- create time in our database
             type VARCHAR(4) NOT NULL, -- buy/sell
             exchange_ctime DOUBLE, -- create time in exchange
             exchange_id INT NOT NULL,
             id_in_exchange VARCHAR(32),
             -- UNIQUE(exchange_id, type, id_id_exchange) -- i think some exchanges reuse order ids?
             currency1 VARCHAR(10) NOT NULL,
             currency2 VARCHAR(10) NOT NULL,
             price DECIMAL(21,8) NOT NULL, -- price of currency1 in currency2, e.g. currency1 = BTC, currency2 = USD, price = 11150
             amount DECIMAL(21,8) NOT NULL,
             status VARCHAR(16) NOT NULL, -- opening (submitting to exchange), open (created and open), pausing, paused, completing, completed, cancelling, cancelled
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

    require SQL::Schema::Versioned;
    my $res = SQL::Schema::Versioned::create_or_update_db_schema(
        dbh => $r->{_dbh}, spec => $db_schema_spec,
    );

    die "Cannot run the application: cannot create/upgrade database schema: $res->[1]"
        unless $res->[0] == 200;

    [200];
}

sub _get_exchange_rates {
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
                log_warn "sell_er and/or buy_er prices are zero or not found, skipped using KlikBCA prices";
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
                log_warn "sell and/or buy prices are zero or not found, skipped using GMC prices";
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

    [200, "OK", {
        usd_idr => $price_usd_idr,
        idr_usd => $price_idr_usd,
    }];
}

sub _check_prices {
    my $r = shift;

    my $dbh = $r->{_dbh};

    my $res = _get_exchange_rates($r);

    [200];
}

$SPEC{app} = {
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
        order_timeout => {
            summary => 'How long should we wait for orders to be completed '.
                'before cancelling them (in seconds)',
            schema => 'posint*',
            default => 2*60,
            tags => ['category:timing'],
        },
    },
    features => {
        dry_run => 1,
    },
};
sub app {
    my %args = @_;

    my $r = $args{-cmdline_r};

    _init($r);

    while (1) {
        _check_prices($r);
        sleep $args{check_prices_frequency};
    }

    [200]; # should not be reached
}

1;
# ABSTRACT:

=head1 SYNOPSIS

Please see included script L<cryp-arbit>.


=head1 SEE ALSO
