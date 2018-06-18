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

# shared between these subcommands: show, arbit
our %args_arbit_common = (
    strategy => {
        summary => 'Which strategy to use for arbitration',
        schema => ['str*', match=>qr/\A\w+\z/],
        default => 'merge_order_book',
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
        'x.name.is_plural' => 1,
        'x.name.singular' => 'base_currency',
        summary => 'Target (crypto)currencies to arbitrate',
        schema => ['array*', of=>'cryptocurrency*', min_len=>1],
        description => <<'_',

If not specified, will list all supported pairs on all the exchanges and include
the base cryptocurrencies that are listed on at least 2 different exchanges (for
arbitrage possibility).

_
    },
    quote_currencies => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'quote_currency',
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
    min_profit_pct => {
        summary => 'What minimum percentage of price difference should '.
            'trigger an arbitrage transaction',
        schema => 'float*',
        default => 0,
        description => <<'_',

Below this percentage number, no order pairs will be made to do the arbitrage.
Note that the price difference that will be considered is the *net* price
difference (after subtracted by trading fees).

Suggestion: If you set this option too high, there might not be any order pairs
possible. If you set this option too low, you will be getting thin profits. Run
`cryp-arbit show` or `cryp-arbit arbit --dry-run` for a while to see what the
average percentage is and then decide at which point you want to perform
arbitrage.

_
    },
    max_order_quote_size => {
        summary => 'What is the maximum amount of a single order',
        schema => 'float*',
        default => 100,
        description => <<'_',

A single order will be limited to not be above this value (in quote currency,
which if fiat will be converted to USD). This is the amount for the buying
(because an arbitrage transaction is comprised of a pair of orders, where one
order is a selling order at a higher quote currency size than the buying order).

For example if you are arbitraging BTC against USD and IDR, and set this option
to 75, then orders will not be above 75 USD. If you are arbitraging LTC against
BTC and set this to 0.03 then orders will not be above 0.03 BTC.

Suggestion: If you set this option too high, a few orders can use up your
inventory (and you might not be getting optimal profit percentage). Also, large
orders can take a while (or too long) to fill. If you set this option too low,
you will hit the exchanges' minimum order size and no orders can be created.
Since we want smaller risk of orders not getting filled quickly, we want small
order sizes. The optimum number range a little above the exchanges' minimum
order size.

_
    },
    max_order_pairs_per_round => {
        summary => 'Maximum number of order pairs to create per round',
        schema => 'posint*',
    },
    min_account_balances => {
        summary => 'What are the minimum account balances',
        schema => ['hash*', {
            each_key => 'cryptoexchange::account*',
            each_value => ['hash*', {
                each_key => 'fiat_or_cryptocurrency*',
                each_value => 'float',
            }],
        }],
    },
);

our %arg_max_order_age = (
    max_order_age => {
        summary => 'How long should we wait for orders to be completed '.
            'before cancelling them (in seconds)',
        schema => 'posint*',
        default => 86400,
        description => <<'_',

Sometimes because of rapid trading and price movement, our order might not be
filled immediately. This setting sets a limit on how long should an order be
left open. After this limit is reached, we cancel the order. The imbalance of
the arbitrage transaction will be recorded.

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
             type VARCHAR(4) NOT NULL, -- "buy" or "sell"
             price DECIMAL(21,8) NOT NULL, -- price to buy (or sell) base_currency in quote_currency, e.g. if base_currency = BTC, quote_currency = USD, price = 11150 means 1 BTC is $11150
             exchange_id INT NOT NULL,
             note VARCHAR(255)
         )',

        'CREATE TABLE order_pair (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             ctime DOUBLE NOT NULL, INDEX(ctime), -- create time in our database

             base_currency VARCHAR(10) NOT NULL, -- the currency we are arbitraging, e.g. LTC
             base_size DECIMAL(21,8) NOT NULL, -- amount of "currency" that we are arbitraging (sell on "sell exchange" and buy on "buy exchange")

             expected_profit_pct DOUBLE NOT NULL, -- expected profit percentage (after trading fees)
             expected_profit DOUBLE NOT NULL, -- expected profit (after trading fees) in quote currency (converted to USD if fiat) if fully executed

             -- we buy "base_size" of "base_currency" on "buy exchange" at
             -- "buy_gross_price_orig" (in "buy_quote_currency") a.k.a
             -- "buy_gross_price" (in "buy_quote_currency" converted to USD if
             -- fiat)

             -- possible statuses/lifecyle: creating (submitting to exchange),
             -- open (created and open), cancelling, cancelled, done

             buy_exchange_id INT NOT NULL,
             buy_account_id INT NOT NULL,
             buy_quote_currency VARCHAR(10) NOT NULL,
             buy_gross_price_orig DECIMAL(21,8) NOT NULL,
             buy_gross_price DECIMAL(21,8) NOT NULL,
             buy_status VARCHAR(16) NOT NULL,

             buy_ctime DOUBLE, -- order create time in "buy_exchange"
             buy_order_id VARCHAR(80),
             buy_actual_price DECIMAL(21,8), -- actual price after we create on exchange
             buy_actual_base_size DECIMAL(21,8), -- actual size after we create on exchange
             buy_filled_base_size DECIMAL(21,8),

             -- then sell the same "base_size" of "base_currency"" on "sell
             -- exchange" (the "base_currency"/"sell_exchange_quote_currency"
             -- market pair) at "sell_gross_price_orig" (in
             -- "sell_exchange_quote_currency") a.k.a "sell_gross_price" (in
             -- "sell_exchange_quote_currency" converted to USD if fiat)

             sell_exchange_id INT NOT NULL,
             sell_account_id INT NOT NULL,
             sell_quote_currency VARCHAR(10) NOT NULL,
             sell_gross_price_orig DECIMAL(21,8) NOT NULL,
             sell_gross_price DECIMAL(21,8) NOT NULL,
             sell_status VARCHAR(16) NOT NULL,

             sell_ctime DOUBLE, -- create time in "sell exchange"
             sell_order_id VARCHAR(80),
             sell_actual_price DECIMAL(21,8), -- actual price after we create on exchange
             sell_actual_base_size DECIMAL(21,8), -- actual size after we create on exchange
             sell_filled_base_size DECIMAL(21,8)
         )',

        'CREATE TABLE arbit_order_log (
            id INT NOT NULL PRIMARY KEY,
            order_pair_id INT NOT NULL,
            type VARCHAR(4) NOT NULL, -- "buy" or "sell"
            summary TEXT NOT NULL
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

sub _get_exchange_client {
    my ($r, $exchange, $account) = @_;

    # if account is unspecified (caller doesn't care which account, e.g. he just
    # wants to get som exchange-related information), then we pick an account
    # from the configuration
    unless (defined $account) {
        my $h = $r->{_cryp}{exchanges}{$exchange};
        die "No configuration found for exchange $exchange. ".
            "Please specify [exchange/$exchange] section in configuration"
            unless keys %$h;
        $account = (keys %$h)[0];
    }

    return $r->{_stash}{exchange_clients}{$exchange}{$account} if
        $r->{_stash}{exchange_clients}{$exchange}{$account};

    my $mod = "App::cryp::Exchange::$exchange";
    $mod =~ s/-/_/g;
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;

    unless ($r->{_cryp}{exchanges}{$exchange}{$account}) {
        die "No configuration found for exchange $exchange (account $account). ".
            "Please specify [exchange/$exchange/$account] section in configuration";
    }

    my $client = $mod->new(
        %{ $r->{_cryp}{exchanges}{$exchange}{$account} }
    );

    $r->{_stash}{exchange_clients}{$exchange}{$account} = $client;
}

sub _get_account_balances {
    my ($r, $no_cache) = @_;

    my $dbh = $r->{_stash}{dbh};

    $r->{_stash}{account_balances} = {};
    for my $e (sort keys %{ $r->{_stash}{account_exchanges} }) {
        my $accounts = $r->{_stash}{account_exchanges}{$e};
        for my $acc (sort keys %$accounts) {
            my $client = _get_exchange_client($r, $e, $acc);
            my $time = time();
            my $res = $client->list_balances;
            unless ($res->[0] == 200) {
                log_error "Couldn't list balances for account %s/%s: %s, skipping account",
                    $e, $acc, $res;
                next ACC;
            }
            for my $rec (@{ $res->[2] }) {
                $rec->{account} = $acc;
                $rec->{account_id} = _get_account_id($r, $e, $acc);
                push @{ $r->{_stash}{account_balances}{$e}{$rec->{currency}} }, $rec;
                $dbh->do(
                    "REPLACE INTO latest_balance (time, account_id, currency, available) VALUES (?,?,?,?)",
                    {},
                    $time, $rec->{account_id}, $rec->{currency}, $rec->{available},
                );
                $dbh->do(
                    "INSERT INTO balance_history (time, account_id, currency, available) VALUES (?,?,?,?)",
                    {},
                    $time, $rec->{account_id}, $rec->{currency}, $rec->{available},
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

    my $client = _get_exchange_client($r, $exchange);

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

# should be used by all subcommands
sub _init {
    my ($r, $opts) = @_;

    $opts //= {};

    my %account_exchanges; # key = exchange safename, value = {account1=>1, account2=>1, ...)

    my $xcat = _exchange_catalog();

  CHECK_ARGUMENTS:
    {
      CHECK_ACCOUNTS:
        {
            last CHECK_ACCOUNTS unless exists $r->{args}{accounts};

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
    }

    my $dbh;
  CONNECT:
    {
        last if $opts->{skip_connect};

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
        last if $opts->{skip_connect};

        require SQL::Schema::Versioned;
        my $res = SQL::Schema::Versioned::create_or_update_db_schema(
            dbh => $r->{_stash}{dbh}, spec => $db_schema_spec,
        );
        die "Cannot run the application: cannot create/upgrade database schema: $res->[1]"
            unless $res->[0] == 200;
    }

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
        for my $e (sort keys %{ $r->{_stash}{account_exchanges} }) {
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
        for my $e (sort keys %{ $r->{_stash}{account_exchanges} }) {
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

sub _format_order_pairs_response {
    my $order_pairs = shift;

    # format for table display
    my @res;
    for my $order_pair (@$order_pairs) {
        my $size = $order_pair->{base_size};
        my ($base_currency, $buy_currency)  = $order_pair->{buy}{pair}  =~ m!(.+)/(.+)!;
        my ($sell_currency) = $order_pair->{sell}{pair} =~ m!/(.+)!;
        my $profit_currency = _is_fiat($buy_currency) ? 'USD' : $buy_currency;

        my $rec = {
            size     => $size,
            currency => $base_currency,
            buy_from => $order_pair->{buy}{exchange},
            buy_currency     => $buy_currency,
            buy_gross_price  => $order_pair->{buy}{gross_price_orig},
            buy_net_price    => $order_pair->{buy}{net_price_orig},
            sell_to          => $order_pair->{sell}{exchange},
            sell_currency    => $sell_currency,
            sell_gross_price => $order_pair->{sell}{gross_price_orig},
            sell_net_price   => $order_pair->{sell}{net_price_orig},
            profit_pct       => $order_pair->{profit_pct},
            profit_currency  => $profit_currency,
            profit           => $order_pair->{profit},
        };
        if (_is_fiat($buy_currency) && $buy_currency ne 'USD') {
            $rec->{buy_gross_price_usd} = $order_pair->{buy}{gross_price};
            $rec->{buy_net_price_usd}   = $order_pair->{buy}{net_price};
        }
        if (_is_fiat($sell_currency) && $sell_currency ne 'USD') {
            $rec->{sell_gross_price_usd} = $order_pair->{sell}{gross_price};
            $rec->{sell_net_price_usd}   = $order_pair->{sell}{net_price};
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

sub _create_orders {
    my $r = shift;

    my $dbh = $r->{_stash}{dbh};

    local $dbh->{RaiseError};

  ORDER_PAIR:
    for my $order_pair (@{ $r->{_stash}{order_pairs} }) {
        my $is_err;
        my $do_cancel_buy_order_on_err;
        my $do_cancel_sell_order_on_err;

        log_debug "Creating order pair on the exchanges: %s ...", $order_pair;
        my $buy  = $order_pair->{buy};
        my $sell = $order_pair->{sell};
        my $buy_eid  = _get_exchange_id($r, $buy ->{exchange});
        my $buy_aid  = _get_account_id ($r, $buy ->{exchange}, $buy ->{account});
        my ($buy_quotecur) = $buy->{pair} =~ m!/(.+)!;
        my $sell_eid = _get_exchange_id($r, $sell->{exchange});
        my $sell_aid = _get_account_id ($r, $sell->{exchange}, $sell->{account});
        my ($sell_quotecur) = $sell->{pair} =~ m!/(.+)!;

        my $time = time();
        # first, insert to database with status 'creating'
        $dbh->do(
            "INSERT INTO order_pair (
               ctime,
               base_currency, base_size,
               expected_profit_pct, expected_profit,

               buy_exchange_id , buy_account_id , buy_quote_currency , buy_gross_price_orig , buy_gross_price , buy_status,
               sell_exchange_id, sell_account_id, sell_quote_currency, sell_gross_price_orig, sell_gross_price, sell_status

             ) VALUES (
               ?,
               ?, ?,
               ?, ?,

               ?, ?, ?, ?, ?, ?,
               ?, ?, ?, ?, ?, ?
             )",

            {},

            $time,
            $order_pair->{base_currency}, $order_pair->{base_size},
            $order_pair->{profit_pct}, $order_pair->{profit},

            $buy_eid , $buy_aid , $buy_quotecur , $buy ->{gross_price_orig}, $buy ->{gross_price}, 'creating',
            $sell_eid, $sell_aid, $sell_quotecur, $sell->{gross_price_orig}, $sell->{gross_price}, 'creating',
        ) or do {
            log_error "Couldn't record order_pair in db: %s, skipping this order pair", $dbh->errstr;
            next ORDER_PAIR;
        };
        my $pair_id = $dbh->last_insert_id("", "", "", "");

        my $buy_client = _get_exchange_client($r, $buy->{exchange}, $buy->{account});
        my $buy_order_id;
      CREATE_BUY_ORDER:
        {
            my $res = $buy_client->create_limit_order(
                pair => $buy->{pair},
                type => 'buy',
                price => $buy->{gross_price_orig},
                base_size => $order_pair->{base_size},
            );
            unless ($res->[0] == 200) {
                log_error "Couldn't create buy order: %s", $res;
                $is_err++;
                goto CLEANUP;
            }
            $buy_order_id = $res->[2]{order_id};
            $do_cancel_buy_order_on_err++;
            my $res2 = $buy_client->get_order(
                pair => $buy->{pair},
                type => 'buy',
                order_id => $buy_order_id,
            );
            unless ($res2->[0] == 200) {
                log_error "Couldn't get buy order: %s", $res2;
                $is_err++;
                goto CLEANUP;
            }
            $dbh->do(
                "UPDATE order_pair SET buy_ctime=?, buy_order_id=?, buy_actual_price=?, buy_actual_base_size=?, buy_status=? WHERE id=?",
                {},
                $res2->[2]{create_time}, $buy_order_id, $res->[2]{price}, $res->[2]{base_size}, 'open',
                $pair_id,
            ) or do {
                log_error "Couldn't update order status in db for buy order: %s", $res2;
            };
        }

        my $sell_client = _get_exchange_client($r, $sell->{exchange}, $sell->{account});
        my $sell_order_id;
      CREATE_SELL_ORDER:
        {
            my $res = $sell_client->create_limit_order(
                pair => $sell->{pair},
                type => 'sell',
                price => $sell->{gross_price_orig},
                base_size => $order_pair->{base_size},
            );
            unless ($res->[0] == 200) {
                log_error "Couldn't create sell order: %s", $res;
                $is_err++;
                goto CLEANUP;
            }
            $sell_order_id = $res->[2]{order_id};
            $do_cancel_sell_order_on_err++;
            my $res2 = $sell_client->get_order(
                pair => $sell->{pair},
                type => 'sell',
                order_id => $sell_order_id,
            );
            unless ($res2->[0] == 200) {
                log_error "Couldn't get sell order: %s", $res2;
                $is_err++;
                goto CLEANUP;
            }
            $dbh->do(
                "UPDATE order_pair SET sell_ctime=?, sell_order_id=?, sell_actual_price=?, sell_actual_base_size=?, sell_status=? WHERE id=?",
                {},
                $res2->[2]{create_time}, $sell_order_id, $res->[2]{price}, $res->[2]{base_size}, 'open',
                $pair_id,
            ) or do {
                log_error "Couldn't update order status in db for sell order: %s", $res2;
            };
        }

      CLEANUP:
        {
            last unless $is_err;
            if ($do_cancel_buy_order_on_err) {
                $dbh->do("UPDATE order_pair SET buy_status='cancelling' WHERE id=?", {}, $pair_id);
                my $res = $buy_client->cancel_order(
                    type => 'buy',
                    pair => $buy->{pair},
                    order_id => $buy_order_id,
                );
                if ($res->[0] != 200) {
                    log_error "Couldn't cancel buy order #%s (order pair ID %d): %s",
                        $buy_order_id, $pair_id, $res;
                } else {
                    $dbh->do("UPDATE order_pair SET buy_status='cancelled' WHERE id=?", {}, $pair_id)
                }
            }
            if ($do_cancel_sell_order_on_err) {
                $dbh->do("UPDATE order_pair SET sell_status='cancelling' WHERE id=?", {}, $pair_id);
                my $res = $sell_client->cancel_order(
                    type => 'sell',
                    pair => $sell->{pair},
                    order_id => $sell_order_id,
                );
                if ($res->[0] != 200) {
                    log_error "Couldn't cancel sell order #%s (order pair ID %d): %s",
                        $sell_order_id, $pair_id, $res;
                } else {
                    $dbh->do("UPDATE order_pair SET sell_status='cancelled' WHERE id=?", {}, $pair_id)
                }
            }
        }
    } # ORDER_PAIR
}

$SPEC{dump_cryp_config} = {
    v => 1.1,
    args => {
    },
};
sub dump_cryp_config {
    my %args = @_;

    my $r = $args{-cmdline_r};
    my $res;

    $res = _init($r, {skip_connect=>1}); return $res unless $res->[0] == 200;

    [200, "OK", $r->{_cryp}];
}

$SPEC{show} = {
    v => 1.1,
    summary => 'Show arbitrage possibilities',
    args => {
        %args_db,
        %args_arbit_common,
        ignore_balance => {
            summary => 'Ignore account balances',
            schema => 'bool*',
            default => 0,
        },
        ignore_min_order_size => {
            summary => 'Ignore minimum order size limitation from exchanges',
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

    $res = $strategy_mod->calculate_order_pairs(r => $r);
    return $res unless $res->[0] == 200;

    #log_trace "order pairs: %s", $res->[2];

    _format_order_pairs_response($res->[2]);
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
        rounds => {
            summary => 'How many rounds',
            schema => 'int*',
            default => 1,
            cmdline_aliases => {
                loop => {is_flag=>1, code=>sub { $_[0]{rounds} = -1 }, summary => 'Shortcut for --rounds -1'},
            },
            description => <<'_',

-1 means unlimited.

_
        },
        frequency => {
            summary => 'How many seconds to wait between rounds (in seconds)',
            schema => 'posint*',
            default => 30,
            description => <<'_',

A round consists of checking prices and then creating arbitraging order pairs.

_
        },
        %arg_max_order_age,
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
    $args{min_profit_pct} > 0 or return [412, "Refusing to do arbitrage with no positive min_profit_pct"];

    my $res;

    $res = _init($r); return $res unless $res->[0] == 200;
    $res = _init_arbit($r); return $res unless $res->[0] == 200;

    log_info "Starting arbitration with '%s' strategy ...", $strategy;

    my $strategy_mod = "App::cryp::arbit::Strategy::$strategy";
    (my $strategy_modpm = "$strategy_mod.pm") =~ s!::!/!g;
    require $strategy_modpm;

    my $round = 0;
  ROUND:
    while (1) {
        $round++;
        log_info "Round #%d", $round;

        $res = $strategy_mod->calculate_order_pairs(r => $r);

        if ($res->[0] == 200) {
            log_debug "Got these order pairs from arbit strategy module: %s",
                $res->[2];
        } else {
            log_error "Got error response from arbit strategy module: %s, ".
                "skipping this round", $res;
            goto SLEEP;
        }
        $r->{_stash}{order_pairs} = $res->[2];

        if ($args{-dry_run}) {
            if ($args{rounds} == 1) {
                log_info "[DRY-RUN] Will not actually be creating order pairs on the exchanges, showing order pairs ...";
                return _format_order_pairs_response($r->{_stash}{order_pairs});
            } else {
                log_info "[DRY-RUN] Will not actually be creating order pairs on the exchanges, waiting for next round ...";
                goto SLEEP;
            }
        }

        _create_orders($r);

        _check_orders($r);

        last if $args{rounds} > 0 && $round >= $args{rounds};

      SLEEP:
        log_trace "Sleeping for %d second(s) before next round ...",
            $args{frequency};
        sleep $args{frequency};
    }

    [200];
}

sub _check_orders {
    my $r = shift;

    my $dbh = $r->{_stash}{dbh};

    my $code_update_buy_status = sub {
        my ($id, $status, $summary) = @_;
        local $dbh->{RaiseError};
        $dbh->do(
            "UPDATE order_pair SET buy_status=? WHERE id=?",
            {},
            $status,
            $id,
        ) or do {
            log_warn "Couldn't update buy status for order pair #%d: %s",
                $id, $dbh->errstr;
            return;
        };
        $dbh->do(
            "INSERT INTO arbit_order_log (order_pair_id, type, summary) VALUES (?,?,?,?)",
            {},
            $id, 'buy', "status changed to $status" . ($summary ? ": $summary" : ""),
        );
    };

    my $code_update_sell_status = sub {
        my ($id, $status, $summary) = @_;
        local $dbh->{RaiseError};
        $dbh->do(
            "UPDATE order_pair SET sell_status=? WHERE id=?",
            {},
            $status,
            $id,
        ) or do {
            log_warn "Couldn't update sell status for order pair #%d: %s",
                $id, $dbh->errstr;
            return;
        };
        $dbh->do(
            "INSERT INTO arbit_order_log (order_pair_id, type, summary) VALUES (?,?,?,?)",
            {},
            $id, 'sell', "status changed to $status" . ($summary ? ": $summary" : ""),
        );
    };

    my $code_update_buy_filled_base_size = sub {
        my ($id, $size, $summary) = @_;
        local $dbh->{RaiseError};
        $dbh->do(
            "UPDATE order_pair SET buy_filled_base_size=? WHERE id=?",
            {},
            $size,
            $id,
        ) or do {
            log_warn "Couldn't update buy filled base size for order pair #%d: %s",
                $id, $dbh->errstr;
            return;
        };
        $dbh->do(
            "INSERT INTO arbit_order_log (order_pair_id, type, summary) VALUES (?,?,?,?)",
            {},
            $id, 'buy', "filled_base_size changed to $size" . ($summary ? ": $summary" : ""),
        );
    };

    my $code_update_sell_filled_base_size = sub {
        my ($id, $size, $summary) = @_;
        local $dbh->{RaiseError};
        $dbh->do(
            "UPDATE order_pair SET sell_filled_base_size=? WHERE id=?",
            {},
            $size,
            $id,
        ) or do {
            log_warn "Couldn't update sell filled base size for order pair #%d: %s",
                $id, $dbh->errstr;
            return;
        };
        $dbh->do(
            "INSERT INTO arbit_order_log (order_pair_id, type, summary) VALUES (?,?,?,?)",
            {},
            $id, 'sell', "filled_base_size changed to $size" . ($summary ? ": $summary" : ""),
        );
    };

    my @open_order_pairs;
    my $sth = $dbh->prepare(
        "SELECT
           op.id id,
           op.ctime ctime,
           CONCAT(op.base_currency, '/', op.buy_quote_currency) buy_pair,
           op.buy_status buy_status,
           (SELECT safename FROM exchange WHERE id=op.buy_exchange_id) buy_exchange,
           (SELECT nickname FROM account WHERE id=op.buy_account_id) buy_account,
           op.buy_order_id buy_order_id,

           op.sell_status sell_status,
           CONCAT(op.base_currency, '/', op.sell_quote_currency) sell_pair,
           (SELECT safename FROM exchange WHERE id=op.sell_exchange_id) sell_exchange,
           (SELECT nickname FROM account WHERE id=op.sell_account_id) sell_account,
           op.sell_order_id sell_order_id
         FROM order_pair op
         WHERE
           op.buy_status  NOT IN ('done','cancelled') OR
           op.sell_status NOT IN ('done','cancelled')
         ORDER BY op.ctime");
    $sth->execute;
    while (my $row = $sth->fetchrow_hashref) {
        push @open_order_pairs, $row;
    }

    my $time = time();
    for my $op (@open_order_pairs) {
        log_debug "Checking order pair #%d (buy status=%s, sell status=%s) ...",
            $op->{id}, $op->{buy_status}, $op->{sell_status};

      CHECK_BUY_ORDER: {
            last if $op->{buy_status} =~ /\A(done|cancelled)\z/;
            my $client = _get_exchange_client($r, $op->{buy_exchange}, $op->{buy_account});
            my $res = $client->get_order(pair=>$op->{buy_pair}, type=>'buy', order_id=>$op->{buy_order_id});
            if ($res->[0] == 404) {
                # assume 404 as order which was never filled and got cancelled.
                # some exchanges, e.g. gdax return 404 for such orders
                $code_update_buy_status->($op->{id}, 'cancelled', 'not found via get_order(), assume cancelled without being filled');
                last;
            } elsif ($res->[0] != 200) {
                log_error "Couldn't get buy order %s (pair %s): %s",
                    $op->{buy_order_id}, $op->{buy_pair}, $res;
                last;
            } else {
                $code_update_buy_status->($op->{id}, $res->[2]{status});
                $code_update_buy_filled_base_size->($op->{id}, $res->[2]{filled_base_size});
            }
        } # CHECK_BUY_ORDER

      CHECK_SELL_ORDER: {
            last if $op->{sell_status} =~ /\A(done|cancelled)\z/;
            my $client = _get_exchange_client($r, $op->{sell_exchange}, $op->{sell_account});
            my $res = $client->get_order(pair=>$op->{sell_pair}, type=>'sell', order_id=>$op->{sell_order_id});
            if ($res->[0] == 404) {
                # assume 404 as order which was never filled and got cancelled.
                # some exchanges, e.g. gdax return 404 for such orders
                $code_update_sell_status->($op->{id}, 'cancelled', 'not found via get_order(), assume cancelled without being filled');
                last;
            } elsif ($res->[0] != 200) {
                log_error "Couldn't get sell order %s (pair %s): %s",
                    $op->{sell_order_id}, $op->{sell_pair}, $res;
                last;
            } else {
                $code_update_sell_status->($op->{id}, $res->[2]{status});
                $code_update_sell_filled_base_size->($op->{id}, $res->[2]{filled_base_size});
            }
        } # CHECK_SELL_ORDER
    }
}

$SPEC{check_orders} = {
    v => 1.1,
    summary => 'Check the orders that have been created',
    description => <<'_',

This subcommand will check the orders that have been created previously by
`arbit` subcommand. It will update the order status and filled size (if still
open). It will cancel (give up) the orders if deemed too old.

_
    args => {
        %args_db,
        %arg_max_order_age,
    },
};
sub check_orders {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $res;

    # [ux] remove extraneous arguments supplied by config
    delete $r->{args}{accounts};

    $res = _init($r); return $res unless $res->[0] == 200;

    _check_orders($r);
    [200];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

Please see included script L<cryp-arbit>.


=head1 DESCRIPTION

=head2 Glossary

=over

=item * inventory

=item * order pair

=back


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
   {exchange_pairs}            # key=exchange safename, value=[{name=>PAIR1, min_base_size=>..., min_quote_size=>...}, ...]
   {order_pairs}               # result from calculate_order_pairs()
   {quote_currencies}          # what currencies we use to buy/sell the base currencies
   {quote_currencies_for}      # key=base currency, value={quotecurrency1 => 1, quotecurrency2=>1, ...}
   {trading_fees}              # key=exchange safename, value={coin1=>num (in percent) market taker fees, ...}, ':default' for all other coins, ':default' for all other exchanges


=head1 SEE ALSO
