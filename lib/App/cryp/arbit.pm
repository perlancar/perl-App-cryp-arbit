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

# shared between these subcommands: show
our %args_arbit_common = (
    strategy => {
        summary => 'Which strategy to use for arbitration',
        schema => ['str*', match=>qr/\A\w+\z/],
        default => 'merge_order_book',
        tags => ['category:strategy'],
        description => <<'_',

Strategy is implemented in a `App::cryp::arbit::Strategy::*` perl module.

_
    },
    accounts => {
        summary => 'Cryptoexchange accounts',
        schema => ['array*', of=>'cryptoexchange::account', min_len=>2],
        description => <<'_',

There should at least be two accounts, on at least two different
cryptoexchanges. If not specified, all accounts listed on the configuration file
will be included. Note that it's possible to include two or more accounts on the
same cryptoexchange.

_
    },
    base_currencies => {
        summary => 'Target (crypto)currencies to arbitrate',
        schema => ['array*', of=>'cryptocurrency*', min_len=>1],
        description => <<'_',

If not specified, will list all supported pairs on all the exchanges and include
the base cryptocurrencies that are listed on at least 2 different exchanges (for
arbitrage possibility).

_
    },
    quote_currencies => {
        summary => 'The currencies to exchange (buy/sell) the target currencies',
        schema => ['array*', of=>'fiat_or_cryptocurrency*', min_len=>1],
        description => <<'_',

You can have fiat currencies as the quote currencies, to buy/sell the target
(base) currencies during arbitrage. For example, to arbitrage LTC against USD
and IDR, `base_currencies` is ['BTC'] and `quote_currencies` is ['USD', 'IDR'].

You can also arbitrage cryptocurrencies against other cryptocurrency (usually
BTC, "the USD of cryptocurrencies"). For example, to arbitrage XMR and LTC
against BTC, `base_currencies` is ['XMR', 'LTC'] and `quote_currencies` is
['BTC'].

_
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
             safename VARCHAR(100) NOT NULL, UNIQUE(safename)
         )',

        # XXX later move to cryp-folio?
        'CREATE TABLE account (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             exchange_id INT NOT NULL,
             nickname VARCHAR(64) NOT NULL,
             UNIQUE(exchange_id,nickname),
             note VARCHAR(255)
         )',

        # XXX later move to cryp-folio?
        'CREATE TABLE latest_balance (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL,
             account_id INT NOT NULL,
             currency VARCHAR(10) NOT NULL,
             UNIQUE(account_id, currency),
             available DECIMAL(21,8) NOT NULL
         )',

        # XXX later move to cryp-folio?
        'CREATE TABLE balance_history (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL,
             account_id INT NOT NULL,
             currency VARCHAR(10) NOT NULL,
             UNIQUE(time, account_id, currency),
             available DECIMAL(21,8) NOT NULL
         )',

        # XXX later move to cryp-folio
        'CREATE TABLE price (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             time DOUBLE NOT NULL, INDEX(time),
             base_currency VARCHAR(10) NOT NULL,
             quote_currency VARCHAR(10) NOT NULL,
             type VARCHAR(4) NOT NULL,
             price DECIMAL(21,8) NOT NULL, -- price to buy (or sell) base_currency in quote_currency, e.g. if base_currency = BTC, quote_currency = USD, price = 11150 means 1 BTC is $11150
             exchange_id INT NOT NULL,
             note VARCHAR(255)
         )',

        'CREATE TABLE order_pair (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             ctime DOUBLE NOT NULL, INDEX(ctime), -- create time in our database

             currency VARCHAR(10) NOT NULL, -- the currency we are arbitraging, e.g. LTC
             size DECIMAL(21,8) NOT NULL, -- amount of "currency" that we are arbitraging (sell on "sell_exchange" and buy on "buy_exchange")

             -- we sell "amount" of "currency"" on "sell exchange" (the "currency"/"sell_exchange_currency" market pair) at "sell_price" (in "sell_exchange_currency")
             sell_account_id INT NOT NULL,
             sell_exchange_id INT NOT NULL,
             sell_exchange_currency VARCHAR(10) NOT NULL,
             sell_exchange_ctime DOUBLE, -- create time in "sell exchange"
             sell_exchange_order_id VARCHAR(32),
             sell_exchange_price DECIMAL(21,8) NOT NULL, -- price of "currency" in "sell_exchange_currency" when selling
             sell_price DECIMAL(21,8) NOT NULL, -- price of "currency" in "sell_exchange_currency" (converted USD if fiat) when selling, should be > "buy_price"
             sell_remaining DECIMAL(21,8) NOT NULL,
             sell_order_status VARCHAR(16) NOT NULL,

             -- then buy the same "amount" of "currency" on "buy_exchange" at "buy_price" (in "buy_exchange_currency")
             buy_account_id INT NOT NULL,
             buy_exchange_id INT NOT NULL,
             buy_exchange_currency VARCHAR(10) NOT NULL,
             buy_exchange_ctime DOUBLE, -- order create time in "buy_exchange"
             buy_exchange_order_id VARCHAR(32),
             buy_exchange_price DECIMAL(21,8) NOT NULL, -- price of "currency" in "buy_exchange_currency" when buying
             buy_price DECIMAL(21,8) NOT NULL, -- price of "currency" in "buy_exchange_currency" (converted to USD if fiat) when buying, should be < "sell_price"
             buy_remaining DECIMAL(21,8) NOT NULL,
             buy_status VARCHAR(16) NOT NULL,

             -- possible statuses: dummy, opening (submitting to exchange), open (created and open), cancelling, cancelled, done

             profit_pct DOUBLE NOT NULL, -- predicted profit percentage (after trading fees)
             profit_size DOUBLE NOT NULL, -- predicted profit size (after trading fees) in quote currency (converted to USD if fiat) if fully executed

             note VARCHAR(255)
         )',
    ],
};

my $fnum4 = [number => {precision=>4}];
my $fnum8 = [number => {precision=>8}];

sub _exchange_catalog {
    state $xcat = do {
        require CryptoExchange::Catalog;
        CryptoExchange::Catalog->new;
    };
    $xcat;
}

# XXX move to App::cryp::Util or folio? given a safename, get or assign exchange
# numeric ID from the database
sub _get_exchange_id {
    my ($r, $exchange) = @_;

    return $r->{_stash}{exchange_ids}{$exchange} if
        $r->{_stash}{exchange_ids}{$exchange};

    my $xcat = _exchange_catalog();
    my $rec = $xcat->by_safename($exchange);
    $rec or die "BUG: Unknown exchange '$exchange'";

    my $dbh = $r->{_stash}{dbh};

    my ($eid) = $dbh->selectrow_array("SELECT id FROM exchange WHERE safename=?", {}, $exchange);
    unless ($eid) {
        $dbh->do("INSERT INTO exchange (safename) VALUES (?)", {},
                 $exchange);
        $eid = $dbh->last_insert_id("","","","");
    }

    $r->{_stash}{exchange_ids}{$exchange} = $eid;
    $eid;
}

sub _get_account_id {
    my ($r, $exchange, $account) = @_;

    return $r->{_stash}{account_ids}{$exchange}{$account} if
        $r->{_stash}{account_ids}{$exchange}{$account};

    my $dbh = $r->{_stash}{dbh};

    my $eid = _get_exchange_id($r, $exchange);

    my ($aid) = $dbh->selectrow_array("SELECT id FROM account WHERE exchange_id=? AND nickname=?", {}, $eid, $account);
    unless ($aid) {
        $dbh->do("INSERT INTO account (exchange_id,nickname) VALUES (?,?)", {}, $eid, $account);
        $aid = $dbh->last_insert_id("","","","");
    }

    $r->{_stash}{account_ids}{$exchange}{$account} = $aid;
    $aid;
}

sub _sort_account_balances {
    my $account_balances = shift;

    for my $e (keys %$account_balances) {
        my $balances = $account_balances->{$e};
        for my $cur (keys %$balances) {
            $balances->{$cur} = [
                grep { $_->{available} >= 1e-8 }
                    sort { $b->{available} <=> $a->{available} }
                    @{ $balances->{$cur} }
                ];
        }
    }
}

sub _get_account_balances {
    my ($r, $no_cache) = @_;

    my $dbh = $r->{_stash}{dbh};
    $r->{_stash}{account_balances} = {};

    for my $e (sort keys %{ $r->{_stash}{exchange_clients} }) {
        my $clients = $r->{_stash}{exchange_clients}{$e};
      ACC:
        for my $acc (sort keys %$clients) {
            my $aid = _get_account_id($r, $e, $acc);
            my $client = $clients->{$acc};
            my $time = time();
            my $res = $client->list_balances;
            unless ($res->[0] == 200) {
                log_error "Couldn't list balances for account %s/%s: %s, skipping account",
                    $e, $acc, $res;
                next ACC;
            }
            for my $rec (@{ $res->[2] }) {
                $rec->{account} = $acc;
                $rec->{account_id} = $aid;
                push @{ $r->{_stash}{account_balances}{$e}{$rec->{currency}} }, $rec;
                $dbh->do(
                    "REPLACE INTO latest_balance (time, account_id, currency, available) VALUES (?,?,?,?)",
                    {},
                    $time, $aid, $rec->{currency}, $rec->{available},
                );
                $dbh->do(
                    "INSERT INTO balance_history (time, account_id, currency, available) VALUES (?,?,?,?)",
                    {},
                    $time, $aid, $rec->{currency}, $rec->{available},
                );
            } # for rec
        } # for account
    } # for exchange

    # sort by largest available balance first
    _sort_account_balances($r->{_stash}{account_balances});

    #log_trace "account_balances: %s", $r->{_stash}{account_balances};
    $r->{_stash}{account_balances};
}

sub _get_exchange_pairs {
    my ($r, $exchange) = @_;

    return $r->{_stash}{exchange_pairs}{$exchange} if
        $r->{_stash}{exchange_pairs}{$exchange};

    my $clients = $r->{_stash}{exchange_clients}{$exchange};
    my $client = $clients->{ (sort keys %$clients)[0] };

    my $res = $client->list_pairs(detail=>1);
    if ($res->[0] == 200) {
        $r->{_stash}{exchange_pairs}{$exchange} = $res->[2];
    } else {
        log_error "Couldn't list pairs on %s: %s, ".
            "skipping this exchange", $exchange, $res;
        $r->{_stash}{exchange_pairs}{$exchange} = [];
    }

    $r->{_stash}{exchange_pairs}{$exchange};
}

sub _get_trading_fee {
    my ($r, $exchange, $currency) = @_;

    my $fees = $r->{_stash}{trading_fees};
    my $fees_exchange = $fees->{$exchange} // $fees->{':default'};
    my $fee = $fees_exchange->{$currency} // $fees_exchange->{':default'};
}

sub _is_fiat {
    require Locale::Codes::Currency_Codes;
    no warnings 'once';
    my $code = shift;
    $Locale::Codes::Data{'currency'}{'code2id'}{alpha}{uc $code} ? 1:0;
}

sub _init {
    my $r = shift;

    my %account_exchanges; # key = exchange safename, value = {account1=>1, account2=>1, ...)

    my $xcat = _exchange_catalog();

  CHECK_ARGUMENTS:
    {
        # accounts: there must be at least two accounts on two different
        # exchanges
        return [400, "Please specify at least two accounts"]
            unless $r->{args}{accounts} && @{ $r->{args}{accounts} } >= 2;
        for (@{ $r->{args}{accounts} }) {
            m!(.+)/(.+)! or return [400, "Invalid account '$_', please use EXCHANGE/ACCOUNT syntax"];
            my ($xchg, $acc) = ($1, $2);
            unless (exists $account_exchanges{$xchg}) {
                my $rec = $xcat->by_safename($xchg);
                return [400, "Unknown exchange '$xchg'"] unless $rec;
                return [400, "Exchange '$xchg' is not assigned short code yet. ".
                            "please contact the maintainer of CryptoExchange::Catalog ".
                            "to add one for it"] unless $rec->{code};
            }
            $account_exchanges{$xchg}{$acc} = 1;
        }
        return [400, "Please specify accounts on at least two ".
                    "cryptoexchanges, you only specify account(s) on " .
                    join(", ", keys %account_exchanges)]
            unless keys(%account_exchanges) >= 2;
        $r->{_stash}{account_exchanges} = \%account_exchanges;
    }

    my $dbh;
  CONNECT:
    {
        require DBIx::Connect::MySQL;
        log_trace "Connecting to database ...";
        $r->{_stash}{dbh} = DBIx::Connect::MySQL->connect(
            "dbi:mysql:database=$r->{args}{db_name}",
            $r->{args}{db_username},
            $r->{args}{db_password},
            {RaiseError => 1},
        );
        $dbh = $r->{_stash}{dbh};
    }

  SETUP_SCHEMA:
    {
        require SQL::Schema::Versioned;
        my $res = SQL::Schema::Versioned::create_or_update_db_schema(
            dbh => $r->{_stash}{dbh}, spec => $db_schema_spec,
        );
        die "Cannot run the application: cannot create/upgrade database schema: $res->[1]"
            unless $res->[0] == 200;
    }

  INSTANTIATE_EXCHANGE_CLIENTS:
    {
        my $time = time();

        for my $exchange (sort keys %account_exchanges) {

            my $mod = "App::cryp::Exchange::$exchange";
            $mod =~ s/-/_/g;
            (my $modpm = "$mod.pm") =~ s!::!/!g;
            require $modpm;

            my $accounts = $account_exchanges{$exchange};
            for my $account (sort keys %$accounts) {
                # assign an ID to the exchange, if not already so
                my $eid = _get_exchange_id($r, $exchange);
                $r->{_stash}{exchange_ids}{$exchange} = $eid;

                unless ($r->{_cryp}{exchanges}{$exchange}{$account}) {
                    return [400, "No configuration found for exchange $exchange (account $account). ".
                                "Please specify [exchange/$exchange/$account] section in configuration"];
                }
                my $client = $mod->new(
                    %{ $r->{_cryp}{exchanges}{$exchange}{$account} }
                );
                $r->{_stash}{exchange_clients}{$exchange}{$account} = $client;
            } # account
        } # exchange
    } # INSTANTIATE_EXCHANGE_CLIENTS

    [200];
}

sub _init_arbit {
    my $r = shift;

  DETERMINE_QUOTE_CURRENCIES:
    {
        my @quotecurs;
        my %fiatquotecurs; # key=fiat, value=1
        my @quotecurs_arg = @{ $r->{args}{quote_currencies} // [] };
        my %quotecur_exchanges; # key=(cryptocurrency code or ':fiat'), value={exchange1=>1, ...}

        # list pairs on all exchanges
        for my $e (sort keys %{ $r->{_stash}{exchange_clients} }) {
            my $clients = $r->{_stash}{exchange_clients}{$e};
            # pick first account
            my $acc = (sort keys %$clients)[0];
            my $client = $clients->{$acc};
            my $pair_recs = _get_exchange_pairs($r, $e);
            for my $pair_rec (@$pair_recs) {
                my $pair = $pair_rec->{name};
                my ($basecur, $quotecur) = split m!/!, $pair;
                # consider all fiat currencies as a single ":fiat" because we
                # assume fiat currencies can be converted from one to the aother
                # at a stable rate.
                my $key;
                if (_is_fiat($quotecur)) {
                    $key = ':fiat';
                    $fiatquotecurs{$quotecur} = 1;
                } else {
                    $key = $quotecur;
                }
                $quotecur_exchanges{$key}{$e} = 1;
            }
        }

        # only consider quote currencies that are traded in >1 exchanges, for
        # arbitrage possibility.
        my @possible_quotecurs = grep { keys(%{$quotecur_exchanges{$_}}) > 1 }
            sort keys %quotecur_exchanges;
        # convert back fiat currencies back to their original
        if (grep {':fiat'} @possible_quotecurs) {
            @possible_quotecurs = grep {$_ ne ':fiat'} @possible_quotecurs;
            push @possible_quotecurs, sort keys %fiatquotecurs;
        }

        if (@quotecurs_arg) {
            my @impossible_quotecurs;
            for my $c (@quotecurs_arg) {
                if (grep { $c eq $_ } @possible_quotecurs) {
                    push @quotecurs, $c;
                } else {
                    push @impossible_quotecurs, $c;
                }
            }
            if (@impossible_quotecurs) {
                log_warn "The following quote currencies are not traded on at least two exchanges: %s, excluding these quote currencies",
                    \@impossible_quotecurs;
            }
        } else {
            log_warn "Will be arbitraging using these quote currencies: %s",
                \@possible_quotecurs;
            @quotecurs = @possible_quotecurs;
        }

        $r->{_stash}{quote_currencies} = \@quotecurs;
    } # DETERMINE_QUOTE_CURRENCIES

    # determine possible base currencies to arbitrage against
  DETERMINE_BASE_CURRENCIES:
    {

        my @basecurs;
        my @basecurs_arg = @{ $r->{args}{base_currencies} // [] };
        my %basecur_exchanges; # key=currency code, value={exchange1=>1, ...}

        # list pairs on all exchanges
        for my $e (sort keys %{ $r->{_stash}{exchange_clients} }) {
            my $clients = $r->{_stash}{exchange_clients}{$e};
            # pick first account
            my $acc = (sort keys %$clients)[0];
            my $client = $clients->{$acc};
            my $pair_recs = _get_exchange_pairs($r, $e);
            for my $pair_rec (@$pair_recs) {
                my $pair = $pair_rec->{name};
                my ($basecur, $quotecur) = split m!/!, $pair;
                next unless grep { $_ eq $quotecur } @{ $r->{_stash}{quote_currencies} };
                $basecur_exchanges{$basecur}{$e} = 1;
            }
        }

        # only consider base currencies that are traded in >1 exchanges, for
        # arbitrage possibility
        my @possible_basecurs = grep { keys(%{$basecur_exchanges{$_}}) > 1 }
            keys %basecur_exchanges;

        if (@basecurs_arg) {
            my @impossible_basecurs;
            for my $c (@basecurs_arg) {
                if (grep { $c eq $_ } @possible_basecurs) {
                    push @basecurs, $c;
                } else {
                    push @impossible_basecurs, $c;
                }
            }
            if (@impossible_basecurs) {
                log_warn "The following base currencies are not traded on at least two exchanges: %s, excluding these base currencies",
                    \@impossible_basecurs;
            }
        } else {
            log_warn "Will be arbitraging these base currencies that are traded on at least two exchanges: %s",
                \@possible_basecurs;
            @basecurs = @possible_basecurs;
        }

        return [412, "No base currencies possible for arbitraging"] unless @basecurs;
        $r->{_stash}{base_currencies} = \@basecurs;
    } # DETERMINE_BASE_CURRENCIES

  DETERMINE_TRADING_FEES:
    {
        # XXX hardcoded for now
        $r->{_stash}{trading_fees} = {
            ':default' => {':default'=>0.3},
            'indodax'  => {':default'=>0.3},
            'gdax'     => {BTC=>0.25, ':default'=>0.3},
        };
    }

    [200];
}

$SPEC{dump_cryp_config} = {
    v => 1.1,
    args => {
    },
};
sub dump_cryp_config {
    my %args = @_;

    my $r = $args{-cmdline_r};

    [200, "OK", $r->{_cryp}];
}

$SPEC{show} = {
    v => 1.1,
    summary => 'Show arbitrage possibilities',
    args => {
        %args_db,
        %args_arbit_common,
        min_profit_pct => {
            summary => 'What minimum percentage of price difference should '.
                'be considered',
            schema => 'float*',
            default => 0,
        },
        disregard_balance => {
            summary => 'Disregard account balances',
            schema => 'bool*',
            default => 0,
        },
    },
};
sub show {
    my %args = @_;

    my $r = $args{-cmdline_r};
    # XXX schema
    my $strategy = $args{strategy} // 'merge_order_book';

    my $res;

    $res = _init($r); return $res unless $res->[0] == 200;
    $res = _init_arbit($r); return $res unless $res->[0] == 200;

    my $strategy_mod = "App::cryp::arbit::Strategy::$strategy";
    (my $strategy_modpm = "$strategy_mod.pm") =~ s!::!/!g;
    require $strategy_modpm;

    $res = $strategy_mod->create_order_pairs(r => $r);
    return $res unless $res->[0] == 200;

    #log_trace "order pairs: %s", $res->[2];

    # format for table display
    my @res;
    for my $orderpair (@{ $res->[2] }) {
        my $size = $orderpair->{base_size};
        my ($base_currency, $buy_currency)  = $orderpair->{buy}{pair}  =~ m!(.+)/(.+)!;
        my ($sell_currency) = $orderpair->{sell}{pair} =~ m!/(.+)!;
        my $profit_currency = _is_fiat($buy_currency) ? 'USD' : $buy_currency;

        my $rec = {
            size     => $size,
            currency => $base_currency,
            buy_from => $orderpair->{buy}{exchange},
            buy_currency     => $buy_currency,
            buy_gross_price  => $orderpair->{buy}{gross_price_orig},
            buy_net_price    => $orderpair->{buy}{net_price_orig},
            sell_to          => $orderpair->{sell}{exchange},
            sell_currency    => $sell_currency,
            sell_gross_price => $orderpair->{sell}{gross_price_orig},
            sell_net_price   => $orderpair->{sell}{net_price_orig},
            profit_pct       => $orderpair->{profit_pct},
            profit_currency  => $profit_currency,
            profit           => $orderpair->{profit},
        };
        if (_is_fiat($buy_currency) && $buy_currency ne 'USD') {
            $rec->{buy_gross_price_usd} = $orderpair->{buy}{gross_price};
            $rec->{buy_net_price_usd}   = $orderpair->{buy}{net_price};
        }
        if (_is_fiat($sell_currency) && $sell_currency ne 'USD') {
            $rec->{sell_gross_price_usd} = $orderpair->{sell}{gross_price};
            $rec->{sell_net_price_usd}   = $orderpair->{sell}{net_price};
        }
        push @res, $rec;
    }

    my $resmeta = {};
    $resmeta->{'table.fields'}        = ['size', 'currency', 'buy_from', 'buy_currency', 'buy_gross_price', 'buy_net_price', 'buy_gross_price_usd', 'buy_net_price_usd', 'sell_to', 'sell_currency', 'sell_gross_price', 'sell_net_price', 'sell_gross_price_usd', 'sell_net_price_usd', 'profit_pct', 'profit_currency', 'profit'];
    $resmeta->{'table.field_labels'}  = [undef,  'c',         undef,     'buy_c',        'buy_gross_p',     'buy_net_p',     'buy_gross_p_usd',     'buy_net_p_usd',     undef,     'sell_c',        undef,              undef,            'sell_gross_p_usd',     'sell_net_p_usd',     undef,        'profit_c',        undef];
    $resmeta->{'table.field_formats'} = [$fnum8, undef,      undef,      undef,          $fnum8,            $fnum8,          $fnum8,                $fnum8,              undef,     undef,           $fnum8,             $fnum8,           $fnum8,                 $fnum8,               $fnum4,       undef,             $fnum8];
    $resmeta->{'table.field_aligns'}  = ['right', 'left',   'left',      'left',         'right',           'right',         'right',               'right',             'left',    'left',          'right',            'right',          'right',                'right',              'right',      'left',            'right'];

    [200, "OK", \@res, $resmeta];
}

$SPEC{arbit} = {
    v => 1.1,
    summary => 'Perform arbitrage',
    description => <<'_',

This utility monitors prices of several cryptocurrencies ("base currencies",
e.g. LTC) in several cryptoexchanges. The "quote currency" can be fiat (e.g.
USD, all other fiat currencies will be converted to USD) or another
cryptocurrency (usually BTC).

When it detects a price difference for a base currency that is large enough (see
`min_profit_pct` option), it will perform a buy order on the exchange that has
the lower price and sell the exact same amount of base currency on the exchange
that has the higher price. For example, if on XCHG1 the buy price of LTC 100.01
USD and on XCHG2 the sell price of LTC is 98.80 USD, then this utility will buy
LTC on XCHG2 for 98.80 USD and sell the same amount of LTD on XCHG1 for 100.01
USD. The profit is (100.01 - 98.80 - trading fees) per LTC arbitraged. You have
to maintain enough LTC balance on XCHG1 and enough USD balance on XCHG2.

The balances are called inventories or your working capital. You fill and
transfer inventories manually to refill balances and/or to collect profits.

_
    args => {
        %args_db,
        %args_arbit_common,
        frequency => {
            summary => 'How many seconds to wait between rounds (in seconds)',
            schema => 'posint*',
            default => 30,
            tags => ['category:timing'],
            description => <<'_',

A round consists of checking prices and then creating arbitraging order pairs.

_
        },
        max_order_age => {
            summary => 'How long should we wait for orders to be completed '.
                'before cancelling them (in seconds)',
            schema => 'posint*',
            default => 2*60,
            tags => ['category:limit', 'category:order-pair'],
            description => <<'_',

Sometimes because of rapid trading and price movement, our order might not be
filled immediately. This setting sets a limit on how long should an order be
left open. After this limit is reached, we cancel the order. The imbalance of
the arbitrage transaction will be recorded.

_
        },
        min_profit_pct => {
            summary => 'What minimum percentage of price difference should '.
                'trigger an arbitrage transaction',
            schema => 'float*',
            req => 1,
            description => <<'_',

Below this percentage number, no order pairs will be made to do the arbitrage.
Note that the price difference that will be considered is the *net* price
difference (after subtracted by trading fees).

_
            tags => ['category:profit'],
        },
        max_order_quote_size => {
            summary => 'What is the maximum amount of a single order',
            schema => 'float*',
            default => 100,
            description => <<'_',

A single order will be limited to not be above this value (in quote currency,
which if fiat will be converted to USD). This is the amount for the selling
(because an arbitrage transaction is comprised of a pair of orders, where one
order is a selling order at a higher quote currency size than the buying order).

For example if you are arbitraging BTC against USD and IDR, and set this option
to 50, then orders will not be below 50 USD. If you are arbitraging LTC against
BTC and set this to 0.01 then orders will not be below 0.01 BTC.

Note that order size can also be smaller due to: 1) insufficient demand (when
selling) or supply (when buying) in the order book; 2) insufficient balance of
the inventory.

_
            tags => ['category:limit', 'category:order'],
        },
        min_account_balance => {
            summary => 'What is the minimum account balance',
            schema => 'float*',
            default => 100,
            description => <<'_',

An account will not be used to create more buy order if its quote currency
balance is below this value, or sell order if its base currency balance
(denominated in quote currency) is below this value. If quote currency is fiat,
will use USD.

For example if you are arbitraging BTC against USD and IDR and set this option
to 100, then account balance will be kept at 100 USD minimum.

_
            tags => ['category:limit', 'category:account'],
        },
    },
    features => {
        dry_run => 1,
    },
};
sub arbit {
    my %args = @_;

    my $r = $args{-cmdline_r};
    # XXX schema
    my $strategy = $args{strategy} // 'merge_order_book';

    my $res;

    $res = _init($r); return $res unless $res->[0] == 200;
    $res = _init_arbit($r); return $res unless $res->[0] == 200;

    log_info "Starting arbitration with '%s' strategy ...", $strategy;

    my $strategy_mod = "App::cryp::arbit::Strategy::$strategy";
    (my $strategy_modpm = "$strategy_mod.pm") =~ s!::!/!g;
    require $strategy_modpm;

  ROUND:
    while (1) {
        $res = $strategy_mod->create_order_pairs(r => $r);

        if ($res->[0] == 200) {
            log_debug "Got these orders from arbit strategy module: %s",
                $res->[2];
        } else {
            log_error "Got error response from arbit strategy module: %s, ".
                "skipping this round", $res;
            goto SLEEP;
        }

        if ($args{-dry_run}) {
            log_info "[DRY-RUN] ";
            goto SLEEP;
        }

        #$res = _submit_orders($r, $res->[2]);
        #unless ($res->[0] == 200) {
        #    log_error "Got error response when submitting orders: %s", $res;
        #}

        #$res = _expire_submitted_orders($r);
        #unless ($res->[0] == 200) {
        #    log_error "Got error response when expiring submitted orders: %s",
        #        $res;
        #}

      SLEEP:
        log_trace "Sleeping for %d second(s) before next round ...",
            $args{frequency};
        sleep $args{frequency};
    }

    [200]; # should not be reached
}

1;
# ABSTRACT:

=head1 SYNOPSIS

Please see included script L<cryp-arbit>.


=head1 DESCRIPTION


=head1 INTERNAL NOTES

The cryp app family uses L<Perinci::CmdLine::cryp> which puts cryp-specific
information from the configuration into the $r->{_cryp} hash:

 $r->{_cryp}
   {arbit_strategies}  # from [arbit-strategy/XXX] config sections
   {exchanges}         # from [exchange/XXX(/YYY)?] config sections
   {masternodes}       # from [masternode/XXX(/YYY)?] config sections
   {wallet}            # from [wallet/COIN]

Routines inside this module communicate with one another either using the
database (obviously), or by putting stuffs in C<$r> (the request hash/stash) and
passing C<$r> around. The keys that are used by routines in this module:

 $r->{_stash}
   {dbh}
   {account_balances}          # key=exchange safename, value={currency1 => [{account=>account1, account_id=>aid, available=>..., ...}, {...}]}. value->{currency} sorted by largest available balance first
   {account_exchanges}         # key=exchange safename, value={account1 => 1, ...}
   {account_ids}               # key=exchange safename, value={account1 => numeric ID from db, ...}
   {base_currencies}           # target (crypto)currencies to arbitrage
   {exchange_clients}          # key=exchange safename, value={account1 => $client1, ...}
   {exchange_ids}              # key=exchange safename, value=exchange (numeric) ID from db
   {exchange_recs}             # key=exchange safename, value=hash (from CryptoExchange::Catalog)
   {exchange_coins}            # key=exchange safename, value=[COIN1, COIN2, ...]
   {exchange_pairs}            # key=exchange safename, value=[PAIR1, PAIR2, ...]
   {quote_currencies}          # what currencies we use to buy/sell the base currencies
   {quote_currencies_for}      # key=base currency, value={quotecurrency1 => 1, quotecurrency2=>1, ...}
   {trading_fees}              # key=exchange safename, value={coin1=>num (in percent) market taker fees, ...}, ':default' for all other coins, ':default' for all other exchanges


=head1 SEE ALSO
