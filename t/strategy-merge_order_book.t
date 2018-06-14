#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use App::cryp::arbit::Strategy::merge_order_book;

subtest 'opt:min_profit_pct' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "gdax",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 1.6,
            profit_pct => 1.62634681845904,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 1.6,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'opt:max_order_pairs' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "gdax",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 1.6,
            profit_pct => 1.62634681845904,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
        max_order_pairs   => 1,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'buy & sell size match' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.1,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.1,
            buy => {
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 0.8,
            profit_pct => 1.62634681845904,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'buy size > sell size' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "gdax",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 1.6,
            profit_pct => 1.62634681845904,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.8,
            buy => {
                exchange => "gdax",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            profit => 4.71999999999998,
            profit_pct => 1.19433198380566,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'buy size < sell size' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 1.6,
            profit_pct => 1.62634681845904,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.8,
            buy => {
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 6.32000000000003,
            profit_pct => 1.60601748322831,
            sell => {
                exchange => "indodax",
                gross_price => 500,
                gross_price_orig => 5000000,
                net_price => 499.8,
                net_price_orig => 4998000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'selling account balance (1)' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>0.15}],
        },
        gdax => {
            USD => [{account=>'g1', available=>9999}],
        },
    };

    my $correct_order_pairs = [
        {
            base_size => 0.15,
            buy => {
                account => "g1",
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 1.2,
            profit_pct => 1.62634681845904,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_profit_pct    => 0,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'selling account balance (2)' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>0.15}, {account=>'i2', available=>0.03}],
        },
        gdax => {
            USD => [{account=>'g1', available=>9999}],
        },
    };

    my $correct_order_pairs = [
        {
            base_size => 0.15,
            buy => {
                account => "g1",
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 1.2,
            profit_pct => 1.62634681845904,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.03,
            buy => {
                account => "g1",
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 0.24,
            profit_pct => 1.62634681845904,
            sell => {
                account => "i2",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_profit_pct    => 0,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'selling account balance (3: re-sorting)' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>0.21}, {account=>'i2', available=>0.03}],
        },
        gdax => {
            USD => [{account=>'g1', available=>9999}],
        },
    };

    my $correct_order_pairs = [
        {
            base_size => 0.2,
            buy => {
                account => "g1",
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 1.6,
            profit_pct => 1.62634681845904,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $correct_final_account_balances = {
        gdax => { USD => [{ account => "g1", available => 9900.78 }] },
        indodax => {
            ETH => [
                { account => "i2", available => 0.03 },
                { account => "i1", available => 0.00999999999999998 },
            ],
        },
    };

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_profit_pct    => 0,
        max_order_pairs   => 1,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;

    is_deeply($account_balances, $correct_final_account_balances)
        or diag explain $account_balances;
};

subtest 'buying account balance (1)' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>9999}],
        },
        gdax => {
            USD => [{account=>'g1', available=>50}, {account=>'g2', available=>40}],
        },
    };

    my $correct_order_pairs = [
        {
            base_size => 0.101812258195887,
            buy => {
                account => "g1",
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 0.814498065567094,
            profit_pct => 1.62634681845904,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.0814498065567094,
            buy => {
                account => "g2",
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 0.651598452453675,
            profit_pct => 1.62634681845904,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $correct_final_account_balances = {
        gdax => { USD => [] },
        indodax => { ETH => [{ account => "i1", available => 9998.81673793525 }] },
    };

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_profit_pct    => 0,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;

    is_deeply($account_balances, $correct_final_account_balances)
        or diag explain $account_balances;
};

subtest 'opt:max_order_quote_size' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "gdax",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.17996400719856,  # .{0}
            buy => {
                exchange => "gdax",        # ..{0}
                gross_price => 491.1,      # ..{1}
                gross_price_orig => 491.1, # ..{2}
                net_price => 491.9,        # ..{3}
                net_price_orig => 491.9,   # ..{4}
                pair => "ETH/USD",         # ..{5}
            },                              # .{1}
            profit => 1.43971205758848,     # .{2}
            profit_pct => 1.62634681845904, # .{3}
            sell => {
                exchange => "indodax",       # ..{0}
                gross_price => 500.1,        # ..{1}
                gross_price_orig => 5001000, # ..{2}
                net_price => 499.9,          # ..{3}
                net_price_orig => 4999000,   # ..{4}
                pair => "ETH/IDR",           # ..{5}
            },                              # .{4}
        }, # [0]
        {
            base_size => 0.0200359928014397, # .{0}
            buy => {
                exchange => "gdax",        # ..{0}
                gross_price => 491.1,      # ..{1}
                gross_price_orig => 491.1, # ..{2}
                net_price => 491.9,        # ..{3}
                net_price_orig => 491.9,   # ..{4}
                pair => "ETH/USD",         # ..{5}
            },                               # .{1}
            profit => 0.160287942411518,     # .{2}
            profit_pct => 1.62634681845904,  # .{3}
            sell => {
                exchange => "indodax",       # ..{0}
                gross_price => 500.1,        # ..{1}
                gross_price_orig => 5001000, # ..{2}
                net_price => 499.9,          # ..{3}
                net_price_orig => 4999000,   # ..{4}
                pair => "ETH/IDR",           # ..{5}
            },                               # .{4}
        }, # [1]
        {
            base_size => 0.17996400719856,  # .{0}
            buy => {
                exchange => "gdax",      # ..{0}
                gross_price => 493,      # ..{1}
                gross_price_orig => 493, # ..{2}
                net_price => 494,        # ..{3}
                net_price_orig => 494,   # ..{4}
                pair => "ETH/USD",       # ..{5}
            },                              # .{1}
            profit => 1.0617876424715,      # .{2}
            profit_pct => 1.19433198380566, # .{3}
            sell => {
                exchange => "indodax",       # ..{0}
                gross_price => 500.1,        # ..{1}
                gross_price_orig => 5001000, # ..{2}
                net_price => 499.9,          # ..{3}
                net_price_orig => 4999000,   # ..{4}
                pair => "ETH/IDR",           # ..{5}
            },                              # .{4}
        }, # [2]
        {
            base_size => 0.17996400719856,  # .{0}
            buy => {
                exchange => "gdax",      # ..{0}
                gross_price => 493,      # ..{1}
                gross_price_orig => 493, # ..{2}
                net_price => 494,        # ..{3}
                net_price_orig => 494,   # ..{4}
                pair => "ETH/USD",       # ..{5}
            },                              # .{1}
            profit => 1.0617876424715,      # .{2}
            profit_pct => 1.19433198380566, # .{3}
            sell => {
                exchange => "indodax",       # ..{0}
                gross_price => 500.1,        # ..{1}
                gross_price_orig => 5001000, # ..{2}
                net_price => 499.9,          # ..{3}
                net_price_orig => 4999000,   # ..{4}
                pair => "ETH/IDR",           # ..{5}
            },                              # .{4}
        }, # [3]
        {
            base_size => 0.17996400719856,  # .{0}
            buy => {
                exchange => "gdax",      # ..{0}
                gross_price => 493,      # ..{1}
                gross_price_orig => 493, # ..{2}
                net_price => 494,        # ..{3}
                net_price_orig => 494,   # ..{4}
                pair => "ETH/USD",       # ..{5}
            },                              # .{1}
            profit => 1.0617876424715,      # .{2}
            profit_pct => 1.19433198380566, # .{3}
            sell => {
                exchange => "indodax",       # ..{0}
                gross_price => 500.1,        # ..{1}
                gross_price_orig => 5001000, # ..{2}
                net_price => 499.9,          # ..{3}
                net_price_orig => 4999000,   # ..{4}
                pair => "ETH/IDR",           # ..{5}
            },                              # .{4}
        }, # [4]
        {
            base_size => 0.17996400719856,  # .{0}
            buy => {
                exchange => "gdax",      # ..{0}
                gross_price => 493,      # ..{1}
                gross_price_orig => 493, # ..{2}
                net_price => 494,        # ..{3}
                net_price_orig => 494,   # ..{4}
                pair => "ETH/USD",       # ..{5}
            },                              # .{1}
            profit => 1.0617876424715,      # .{2}
            profit_pct => 1.19433198380566, # .{3}
            sell => {
                exchange => "indodax",       # ..{0}
                gross_price => 500.1,        # ..{1}
                gross_price_orig => 5001000, # ..{2}
                net_price => 499.9,          # ..{3}
                net_price_orig => 4999000,   # ..{4}
                pair => "ETH/IDR",           # ..{5}
            },                              # .{4}
        }, # [5]
        {
            base_size => 0.0801439712057587, # .{0}
            buy => {
                exchange => "gdax",      # ..{0}
                gross_price => 493,      # ..{1}
                gross_price_orig => 493, # ..{2}
                net_price => 494,        # ..{3}
                net_price_orig => 494,   # ..{4}
                pair => "ETH/USD",       # ..{5}
            },                               # .{1}
            profit => 0.472849430113975,     # .{2}
            profit_pct => 1.19433198380566,  # .{3}
            sell => {
                exchange => "indodax",       # ..{0}
                gross_price => 500.1,        # ..{1}
                gross_price_orig => 5001000, # ..{2}
                net_price => 499.9,          # ..{3}
                net_price_orig => 4999000,   # ..{4}
                pair => "ETH/IDR",           # ..{5}
            },                               # .{4}
        }, # [6]
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
        max_order_quote_size => 90,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'opt:max_order_size_as_book_item_size_pct' => sub {
    my $all_buy_orders = [
        {
            base_size        => 1, # *80% = 0.08
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2, # *80% = 0.16
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9, # *80% = 0.72
            exchange         => "gdax",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.16,
            buy => {
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 1.28,
            profit_pct => 1.62634681845904,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.64,
            buy => {
                exchange => "gdax",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            profit => 3.77599999999999,
            profit_pct => 1.19433198380566,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
        max_order_size_as_book_item_size_pct => 80,
    );

    #use DD; dd $order_pairs;

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest 'opt:min_account_balance' => sub {
    my $all_buy_orders = [
        {
            base_size        => 0.2,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
        {
            base_size        => 0.9,
            exchange         => "indodax",
            gross_price      => 500.0,
            gross_price_orig => 5000_000,
            net_price        => 499.8,
            net_price_orig   => 4998_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 1,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
    ];

    my $account_balances = {
        indodax => {
            ETH => [{account=>'i1', available=>0.15}, {account=>'i2', available=>1}, ],
        },
        gdax => {
            USD => [{account=>'g1', available=>9999}],
        },
    };

    my $min_account_balances = {
        "indodax/i1" => {ETH => 0.02},
        "indodax/i2" => {ETH => 0.98},
    };

    my $correct_order_pairs = [
        {
            base_size => 0.13,
            buy => {
                account => "g1",
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 1.04,
            profit_pct => 1.62634681845904,
            sell => {
                account => "i1",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
        {
            base_size => 0.02,
            buy => {
                account => "g1",
                exchange => "gdax",
                gross_price => 491.1,
                gross_price_orig => 491.1,
                net_price => 491.9,
                net_price_orig => 491.9,
                pair => "ETH/USD",
            },
            profit => 0.16,
            profit_pct => 1.62634681845904,
            sell => {
                account => "i2",
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $correct_final_account_balances = {
        gdax => { USD => [{account=>'g1', available=>9925.335}] },
        indodax => { ETH => [] },
    };

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        account_balances  => $account_balances,
        min_account_balances => $min_account_balances,
        min_profit_pct    => 0,
    );

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;

    is_deeply($account_balances, $correct_final_account_balances)
        or diag explain $account_balances;
};

subtest "minimum buy base size" => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "gdax",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.8,
            buy => {
                exchange => "gdax",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            profit => 4.71999999999998,
            profit_pct => 1.19433198380566,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
        exchange_pairs    => {
            gdax => [{base_currency=>"ETH", min_base_size=>0.5}],
        },
    );

    #use DD; dd $order_pairs;

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest "minimum buy quote size" => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "gdax",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.8,
            buy => {
                exchange => "gdax",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            profit => 4.71999999999998,
            profit_pct => 1.19433198380566,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
        exchange_pairs    => {
            gdax => [{base_currency=>"ETH", min_quote_size=>200}],
        },
    );

    #use DD; dd $order_pairs;

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest "minimum sell base size" => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "gdax",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.8,
            buy => {
                exchange => "gdax",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            profit => 4.71999999999998,
            profit_pct => 1.19433198380566,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
        exchange_pairs    => {
            indodax => [{base_currency=>"ETH", min_base_size=>0.5}],
        },
    );

    #use DD; dd $order_pairs;

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

subtest "minimum sell quote size" => sub {
    my $all_buy_orders = [
        {
            base_size        => 1,
            exchange         => "indodax",
            gross_price      => 500.1,
            gross_price_orig => 5001_000,
            net_price        => 499.9,
            net_price_orig   => 4999_000,
            quote_currency   => "IDR",
        },
    ];

    my $all_sell_orders = [
        {
            base_size        => 0.2,
            exchange         => "gdax",
            gross_price      => 491.1,
            gross_price_orig => 491.1,
            net_price        => 491.9,
            net_price_orig   => 491.9,
            quote_currency   => "USD",
        },
        {
            base_size        => 0.9,
            exchange         => "gdax",
            gross_price      => 493.0,
            gross_price_orig => 493.0,
            net_price        => 494.0,
            net_price_orig   => 494.0,
            quote_currency   => "USD",
        },
    ];

    my $correct_order_pairs = [
        {
            base_size => 0.8,
            buy => {
                exchange => "gdax",
                gross_price => 493,
                gross_price_orig => 493,
                net_price => 494,
                net_price_orig => 494,
                pair => "ETH/USD",
            },
            profit => 4.71999999999998,
            profit_pct => 1.19433198380566,
            sell => {
                exchange => "indodax",
                gross_price => 500.1,
                gross_price_orig => 5001000,
                net_price => 499.9,
                net_price_orig => 4999000,
                pair => "ETH/IDR",
            },
        },
    ];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 0,
        exchange_pairs    => {
            indodax => [{base_currency=>"ETH", min_quote_size=>200}],
        },
    );

    #use DD; dd $order_pairs;

    is_deeply($order_pairs, $correct_order_pairs)
        or diag explain $order_pairs;
};

DONE_TESTING:
done_testing;
