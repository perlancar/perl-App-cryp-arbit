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
    summary => 'Cryptocurrency arbitrage utility',
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
    component_name => 'cryp_arbit',
    latest_v => 1,
    provides => [qw/exchange account balance tx price order_pair/],
    install => [
        # XXX later move to cryp-folio?
        'CREATE TABLE exchange (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             shortname VARCHAR(8) NOT NULL, UNIQUE(shortname),
             safename VARCHAR(100) NOT NULL, UNIQUE(safename)
         )',

        # XXX later move to cryp-folio?
        'CREATE TABLE account (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             ctime DOUBLE NOT NULL,
             exchange_id INT NOT NULL,
             note VARCHAR(255)
         )',

        # XXX later move to cryp-folio?
        'CREATE TABLE balance (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL, INDEX(time),
             account_id INT NOT NULL,
             currency VARCHAR(10) NOT NULL,
             amount DECIMAL(21,8) NOT NULL,
             note VARCHAR(255)
         )',

        # XXX create balance_Log? (later move to cryp-folio)?

        # XXX later move to cryp-folio?
        'CREATE TABLE tx (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL, INDEX(time),
             note VARCHAR(255)
         )',

        # XXX later move to cryp-folio
        'CREATE TABLE price (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL, INDEX(time),
             currency1 VARCHAR(10) NOT NULL,
             currency2 VARCHAR(10) NOT NULL,
             price DECIMAL(21,8) NOT NULL, -- price to buy currency1 in currency2, e.g. currency1 = BTC, currency2 = USD, price = 11150
             exchange_id INT NOT NULL,
             note VARCHAR(255)
         )',

        'CREATE TABLE order_pair (
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
        'CREATE TABLE arbit_profit (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL, INDEX(time),
             currency VARCHAR(10) NOT NULL,
             amount DECIMAL(21,8) NOT NULL,
             note VARCHAR(255)
         )',
    ],
};

sub _init {
    my $r = shift;

    my %acc_exchanges; # key = exchange safename, value = (account, ...)

    # check arguments
  CHECK_ARGUMENTS:
    {
        # there must be at least two accounts on two different exchanges
        return [400, "Please specify at least two accounts"]
            unless $r->{args}{accounts} && @{ $r->{args}{accounts} } >= 2;
        for (@{ $r->{args}{accounts} }) {
            m!(.+)/(.+)! or return [400, "Invalid account '$_', please use EXCHANGE/ACCOUNT syntax"];
            $acc_exchanges{$1} //= [];
            push @{ $acc_exchanges{$1} } //= [];
        }
        return [400, "Please specify accounts on at least two cryptoexchanges, ".
                    "you only specify account(s) on " . (keys %exchanges)[0]]
            unless keys(%exchanges) >= 2;
    }

  CONNECT: {
        require DBIx::Connect::MySQL;
        log_trace "Connecting to database ...";
        $r->{_dbh} = DBIx::Connect::MySQL->connect(
            "dbi:mysql:database=$r->{args}{db_name}",
            $r->{args}{db_username},
            $r->{args}{db_password},
            {RaiseError => 1},
        );
        my $dbh = $r->{_dbh};
    }

  SETUP_SCHEMA: {
        require SQL::Schema::Versioned;
        my $res = SQL::Schema::Versioned::create_or_update_db_schema(
            dbh => $r->{_dbh}, spec => $db_schema_spec,
        );
        die "Cannot run the application: cannot create/upgrade database schema: $res->[1]"
            unless $res->[0] == 200;
    }

  INSTANTIATE_API_CLIENTS: {
    {
        my $time = time();

        $dbh->do("INSERT IGNORE INTO exchange (shortname,safename) VALUES ('GDAX','gdax')");
        $dbh->do("INSERT IGNORE INTO exchange (shortname,safename) VALUES ('INDODAX','bitcoin-indonesia')");
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

$SPEC{arbit} = {
    v => 1.1,
    summary => 'Perform arbitrage',
    description => <<'_',

This utility monitors prices of several coins in several cryptoexchanges. When
it detects a price difference for a coin (e.g. BTC) that is large enough (see
`min_price_difference_percentage` option), it will perform buy order on the
exchange that has the lower price (note: the account on this exchange must have
enough base currency balance, e.g. USD if the pair is BTC/USD) and sell order on
the exchange that has the higher price (note: the account on this exchange must
have enough BTC balance).

The balances are called inventories or your working capital. You fill and
transfer inventories manually to refill balances and/or to collect profits.

_
    args => {
        %args_db,
        strategy => {
            summary => 'Which strategy to use for arbitration',
            schema => ['str*', match=>qr/\A\w+\z/],
            default => 'merge_order_book',
            tags => ['category:strategy'],
        },
        accounts => {
            summary => 'Cryptoexchange accounts',
            schema => ['array*', of=>'cryptoexchange::account', min_len=>2],
            description => <<'_',

There should at least be two accounts, with at least two different
cryptoexchanges. If not specified, all accounts listed on the configuration file
will be included. It's possible to include two or more accounts on the same
cryptoexchange.

_
        },
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
            description => <<'_',

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
            req => 1,
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
    my $res = _init($r); return $res unless $res->[0] == 200;

    # XXX schema
    my $strategy = $args{strategy} // 'merge_order_book';

    log_info "Starting arbitration with '%s' strategy ...", $strategy;

    my $strategy_mod = "App::cryp::arbit::Strategy::$strategy";
    (my $strategy_modpm = "$strategy_mod.pm") =~ s!::!/!g;
    require $strategy_modpm;

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


=head1 DESCRIPTION


=head1 INTERNAL NOTES

Routines inside this module communicate with one another either using the
database (obviously), or by putting stuffs in C<$r> (the request hash/stash) and
pass it around. The keys that are used by routines in this module:

 $r->{_dbh}
 $r->{_exchanges}

To be cleaner and more documented, when communicating with routines in other
modules (including C<App::cryp::Arbit::Strategy::*> modules), we use standard
argument passing.


=head1 SEE ALSO
