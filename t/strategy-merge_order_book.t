#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use App::cryp::arbit::Strategy::merge_order_book;

goto L1;

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
            gross_price      => 491.0,
            gross_price_orig => 491.0,
            net_price        => 491.8,
            net_price_orig   => 491.8,
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
                gross_price => 491,
                gross_price_orig => 491,
                net_price => 491.8,
                net_price_orig => 491.8,
                pair => "ETH/USD",
            },
            profit => 6.47999999999997,
            profit_pct => 1.64701098007319,
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

L1:
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
goto DONE_TESTING;

subtest 'real data' => sub {
    my $all_buy_orders = [
  {
    base_size        => "0.35632381", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 496.30512,    # .{2}
    gross_price_orig => "6896000",    # .{3}
    net_price        => 494.81620464, # .{4}
    net_price_orig   => 6875312,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [  0]
  {
    base_size        => "0.01975794", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 496.23315,    # .{2}
    gross_price_orig => 6895000,      # .{3}
    net_price        => 494.74445055, # .{4}
    net_price_orig   => 6874315,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [  1]
  {
    base_size        => "1.00145138", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 495.8733,     # .{2}
    gross_price_orig => 6890000,      # .{3}
    net_price        => 494.3856801,  # .{4}
    net_price_orig   => 6869330,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [  2]
  {
    base_size        => "0.46721760", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 494.79375,    # .{2}
    gross_price_orig => 6875000,      # .{3}
    net_price        => 493.30936875, # .{4}
    net_price_orig   => 6854375,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [  3]
  {
    base_size        => "20.50029823", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 494.72178,     # .{2}
    gross_price_orig => 6874000,       # .{3}
    net_price        => 493.23761466,  # .{4}
    net_price_orig   => 6853378,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [  4]
  {
    base_size        => "0.07275902", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 494.57784,    # .{2}
    gross_price_orig => 6872000,      # .{3}
    net_price        => 493.09410648, # .{4}
    net_price_orig   => 6851384,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [  5]
  {
    base_size        => "0.27645261", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 494.36193,    # .{2}
    gross_price_orig => 6869000,      # .{3}
    net_price        => 492.87884421, # .{4}
    net_price_orig   => 6848393,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [  6]
  {
    base_size        => "0.36918163", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 493.7142,     # .{2}
    gross_price_orig => 6860000,      # .{3}
    net_price        => 492.2330574,  # .{4}
    net_price_orig   => 6839420,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [  7]
  {
    base_size        => "11.65649993", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 492.49071,     # .{2}
    gross_price_orig => 6843000,       # .{3}
    net_price        => 491.01323787,  # .{4}
    net_price_orig   => 6822471,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [  8]
  {
    base_size        => "205.63986963", # .{0}
    exchange         => "indodax",      # .{1}
    gross_price      => 492.41874,      # .{2}
    gross_price_orig => 6842000,        # .{3}
    net_price        => 490.94148378,   # .{4}
    net_price_orig   => 6821474,        # .{5}
    quote_currency   => "IDR",          # .{6}
  }, # [  9]
  {
    base_size        => "0.97860517", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 492.34677,    # .{2}
    gross_price_orig => 6841000,      # .{3}
    net_price        => 490.86972969, # .{4}
    net_price_orig   => 6820477,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 10]
  {
    base_size        => "2.13019335", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 491.69904,    # .{2}
    gross_price_orig => 6832000,      # .{3}
    net_price        => 490.22394288, # .{4}
    net_price_orig   => 6811504,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 11]
  {
    base_size        => "20.19350000", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 491.26722,     # .{2}
    gross_price_orig => 6826000,       # .{3}
    net_price        => 489.79341834,  # .{4}
    net_price_orig   => 6805522,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 12]
  {
    base_size        => "0.01465201", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 491.19525,    # .{2}
    gross_price_orig => 6825000,      # .{3}
    net_price        => 489.72166425, # .{4}
    net_price_orig   => 6804525,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 13]
  {
    base_size        => "1.23409507", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 490.54752,    # .{2}
    gross_price_orig => 6816000,      # .{3}
    net_price        => 489.07587744, # .{4}
    net_price_orig   => 6795552,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 14]
  {
    base_size        => "0.02941176", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 489.396,      # .{2}
    gross_price_orig => 6800000,      # .{3}
    net_price        => 487.927812,   # .{4}
    net_price_orig   => 6779600,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 15]
  {
    base_size        => "3.11323816", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 489.25206,    # .{2}
    gross_price_orig => 6798000,      # .{3}
    net_price        => 487.78430382, # .{4}
    net_price_orig   => 6777606,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 16]
  {
    base_size        => "1.02123917", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 488.38842,    # .{2}
    gross_price_orig => 6786000,      # .{3}
    net_price        => 486.92325474, # .{4}
    net_price_orig   => 6765642,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 17]
  {
    base_size        => "7.58582347", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 487.59675,    # .{2}
    gross_price_orig => 6775000,      # .{3}
    net_price        => 486.13395975, # .{4}
    net_price_orig   => 6754675,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 18]
  {
    base_size        => "0.10000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 485.36568,    # .{2}
    gross_price_orig => 6744000,      # .{3}
    net_price        => 483.90958296, # .{4}
    net_price_orig   => 6723768,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 19]
  {
    base_size        => "0.64324200", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 483.27855,    # .{2}
    gross_price_orig => 6715000,      # .{3}
    net_price        => 481.82871435, # .{4}
    net_price_orig   => 6694855,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 20]
  {
    base_size        => "2.02862149", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 482.199,      # .{2}
    gross_price_orig => 6700000,      # .{3}
    net_price        => 480.752403,   # .{4}
    net_price_orig   => 6679900,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 21]
  {
    base_size        => "0.16823167", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 481.83915,    # .{2}
    gross_price_orig => 6695000,      # .{3}
    net_price        => 480.39363255, # .{4}
    net_price_orig   => 6674915,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 22]
  {
    base_size        => "0.25699073", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 481.40733,    # .{2}
    gross_price_orig => 6689000,      # .{3}
    net_price        => 479.96310801, # .{4}
    net_price_orig   => 6668933,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 23]
  {
    base_size        => "0.00747608", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 481.33536,    # .{2}
    gross_price_orig => 6688000,      # .{3}
    net_price        => 479.89135392, # .{4}
    net_price_orig   => 6667936,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 24]
  {
    base_size        => "6.72902647", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 481.26339,    # .{2}
    gross_price_orig => 6687000,      # .{3}
    net_price        => 479.81959983, # .{4}
    net_price_orig   => 6666939,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 25]
  {
    base_size        => "58.13763326", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 481.19142,     # .{2}
    gross_price_orig => 6686000,       # .{3}
    net_price        => 479.74784574,  # .{4}
    net_price_orig   => 6665942,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 26]
  {
    base_size        => "0.44977511", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 480.0399,     # .{2}
    gross_price_orig => 6670000,      # .{3}
    net_price        => 478.5997803,  # .{4}
    net_price_orig   => 6649990,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 27]
  {
    base_size        => "2.78511536", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 479.75202,    # .{2}
    gross_price_orig => 6666000,      # .{3}
    net_price        => 478.31276394, # .{4}
    net_price_orig   => 6646002,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 28]
  {
    base_size        => "1.02528135", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 478.6005,     # .{2}
    gross_price_orig => 6650000,      # .{3}
    net_price        => 477.1646985,  # .{4}
    net_price_orig   => 6630050,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 29]
  {
    base_size        => "204.30000000", # .{0}
    exchange         => "indodax",      # .{1}
    gross_price      => 478.52853,      # .{2}
    gross_price_orig => 6649000,        # .{3}
    net_price        => 477.09294441,   # .{4}
    net_price_orig   => 6629053,        # .{5}
    quote_currency   => "IDR",          # .{6}
  }, # [ 30]
  {
    base_size        => "0.08846878", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 478.38459,    # .{2}
    gross_price_orig => 6647000,      # .{3}
    net_price        => 476.94943623, # .{4}
    net_price_orig   => 6627059,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 31]
  {
    base_size        => "0.01205182", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 477.73686,    # .{2}
    gross_price_orig => 6638000,      # .{3}
    net_price        => 476.30364942, # .{4}
    net_price_orig   => 6618086,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 32]
  {
    base_size        => "0.00088", # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "476.87",  # .{2}
    gross_price_orig => "476.87",  # .{3}
    net_price        => 475.43939, # .{4}
    net_price_orig   => 475.43939, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 33]
  {
    base_size        => "0.03773585", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 476.80125,    # .{2}
    gross_price_orig => 6625000,      # .{3}
    net_price        => 475.37084625, # .{4}
    net_price_orig   => 6605125,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 34]
  {
    base_size        => "0.0578",  # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "476.69",  # .{2}
    gross_price_orig => "476.69",  # .{3}
    net_price        => 475.25993, # .{4}
    net_price_orig   => 475.25993, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 35]
  {
    base_size        => "93.4854", # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "476.46",  # .{2}
    gross_price_orig => "476.46",  # .{3}
    net_price        => 475.03062, # .{4}
    net_price_orig   => 475.03062, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 36]
  {
    base_size        => "11",     # .{0}
    exchange         => "gdax",   # .{1}
    gross_price      => "476.2",  # .{2}
    gross_price_orig => "476.2",  # .{3}
    net_price        => 474.7714, # .{4}
    net_price_orig   => 474.7714, # .{5}
    quote_currency   => "USD",    # .{6}
  }, # [ 37]
  {
    base_size        => "13",    # .{0}
    exchange         => "gdax",  # .{1}
    gross_price      => "476",   # .{2}
    gross_price_orig => "476",   # .{3}
    net_price        => 474.572, # .{4}
    net_price_orig   => 474.572, # .{5}
    quote_currency   => "USD",   # .{6}
  }, # [ 38]
  {
    base_size        => "11.5",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.82",  # .{2}
    gross_price_orig => "475.82",  # .{3}
    net_price        => 474.39254, # .{4}
    net_price_orig   => 474.39254, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 39]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.76",  # .{2}
    gross_price_orig => "475.76",  # .{3}
    net_price        => 474.33272, # .{4}
    net_price_orig   => 474.33272, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 40]
  {
    base_size        => "1",      # .{0}
    exchange         => "gdax",   # .{1}
    gross_price      => "475.7",  # .{2}
    gross_price_orig => "475.7",  # .{3}
    net_price        => 474.2729, # .{4}
    net_price_orig   => 474.2729, # .{5}
    quote_currency   => "USD",    # .{6}
  }, # [ 41]
  {
    base_size        => "10",      # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.65",  # .{2}
    gross_price_orig => "475.65",  # .{3}
    net_price        => 474.22305, # .{4}
    net_price_orig   => 474.22305, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 42]
  {
    base_size        => "10.9",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.62",  # .{2}
    gross_price_orig => "475.62",  # .{3}
    net_price        => 474.19314, # .{4}
    net_price_orig   => 474.19314, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 43]
  {
    base_size        => "25",      # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.61",  # .{2}
    gross_price_orig => "475.61",  # .{3}
    net_price        => 474.18317, # .{4}
    net_price_orig   => 474.18317, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 44]
  {
    base_size        => "0.22699758", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 475.57776,    # .{2}
    gross_price_orig => 6608000,      # .{3}
    net_price        => 474.15102672, # .{4}
    net_price_orig   => 6588176,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 45]
  {
    base_size        => "1.45017", # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.51",  # .{2}
    gross_price_orig => "475.51",  # .{3}
    net_price        => 474.08347, # .{4}
    net_price_orig   => 474.08347, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 46]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.47",  # .{2}
    gross_price_orig => "475.47",  # .{3}
    net_price        => 474.04359, # .{4}
    net_price_orig   => 474.04359, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 47]
  {
    base_size        => "1.07819", # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.45",  # .{2}
    gross_price_orig => "475.45",  # .{3}
    net_price        => 474.02365, # .{4}
    net_price_orig   => 474.02365, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 48]
  {
    base_size        => "0.09133757", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 475.43382,    # .{2}
    gross_price_orig => 6606000,      # .{3}
    net_price        => 474.00751854, # .{4}
    net_price_orig   => 6586182,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 49]
  {
    base_size        => "1.11111", # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.41",  # .{2}
    gross_price_orig => "475.41",  # .{3}
    net_price        => 473.98377, # .{4}
    net_price_orig   => 473.98377, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 50]
  {
    base_size        => "0.07570023", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 475.36185,    # .{2}
    gross_price_orig => 6605000,      # .{3}
    net_price        => 473.93576445, # .{4}
    net_price_orig   => 6585185,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 51]
  {
    base_size        => "10.581",  # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.36",  # .{2}
    gross_price_orig => "475.36",  # .{3}
    net_price        => 473.93392, # .{4}
    net_price_orig   => 473.93392, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 52]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.31",  # .{2}
    gross_price_orig => "475.31",  # .{3}
    net_price        => 473.88407, # .{4}
    net_price_orig   => 473.88407, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 53]
  {
    base_size        => "1.21165", # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.3",   # .{2}
    gross_price_orig => "475.3",   # .{3}
    net_price        => 473.8741,  # .{4}
    net_price_orig   => 473.8741,  # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 54]
  {
    base_size        => "20.5146", # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.27",  # .{2}
    gross_price_orig => "475.27",  # .{3}
    net_price        => 473.84419, # .{4}
    net_price_orig   => 473.84419, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 55]
  {
    base_size        => "27.31643", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "475.24",   # .{2}
    gross_price_orig => "475.24",   # .{3}
    net_price        => 473.81428,  # .{4}
    net_price_orig   => 473.81428,  # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 56]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.21",  # .{2}
    gross_price_orig => "475.21",  # .{3}
    net_price        => 473.78437, # .{4}
    net_price_orig   => 473.78437, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 57]
  {
    base_size        => "0.01",   # .{0}
    exchange         => "gdax",   # .{1}
    gross_price      => "475.2",  # .{2}
    gross_price_orig => "475.2",  # .{3}
    net_price        => 473.7744, # .{4}
    net_price_orig   => 473.7744, # .{5}
    quote_currency   => "USD",    # .{6}
  }, # [ 58]
  {
    base_size        => "0.28731212", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "475.12",     # .{2}
    gross_price_orig => "475.12",     # .{3}
    net_price        => 473.69464,    # .{4}
    net_price_orig   => 473.69464,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [ 59]
  {
    base_size        => "0.02104776", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "475.11",     # .{2}
    gross_price_orig => "475.11",     # .{3}
    net_price        => 473.68467,    # .{4}
    net_price_orig   => 473.68467,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [ 60]
  {
    base_size        => "0.2614397", # .{0}
    exchange         => "gdax",      # .{1}
    gross_price      => "475.1",     # .{2}
    gross_price_orig => "475.1",     # .{3}
    net_price        => 473.6747,    # .{4}
    net_price_orig   => 473.6747,    # .{5}
    quote_currency   => "USD",       # .{6}
  }, # [ 61]
  {
    base_size        => "0.02",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.08",  # .{2}
    gross_price_orig => "475.08",  # .{3}
    net_price        => 473.65476, # .{4}
    net_price_orig   => 473.65476, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 62]
  {
    base_size        => "3",       # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.05",  # .{2}
    gross_price_orig => "475.05",  # .{3}
    net_price        => 473.62485, # .{4}
    net_price_orig   => 473.62485, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 63]
  {
    base_size        => "1.4728",  # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "475.03",  # .{2}
    gross_price_orig => "475.03",  # .{3}
    net_price        => 473.60491, # .{4}
    net_price_orig   => 473.60491, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 64]
  {
    base_size        => "37.47430939", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 475.002,       # .{2}
    gross_price_orig => 6600000,       # .{3}
    net_price        => 473.576994,    # .{4}
    net_price_orig   => 6580200,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 65]
  {
    base_size        => "4.84052632", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "475",        # .{2}
    gross_price_orig => "475",        # .{3}
    net_price        => 473.575,      # .{4}
    net_price_orig   => 473.575,      # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [ 66]
  {
    base_size        => "27.623",  # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.97",  # .{2}
    gross_price_orig => "474.97",  # .{3}
    net_price        => 473.54509, # .{4}
    net_price_orig   => 473.54509, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 67]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.92",  # .{2}
    gross_price_orig => "474.92",  # .{3}
    net_price        => 473.49524, # .{4}
    net_price_orig   => 473.49524, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 68]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.83",  # .{2}
    gross_price_orig => "474.83",  # .{3}
    net_price        => 473.40551, # .{4}
    net_price_orig   => 473.40551, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 69]
  {
    base_size        => "1.64854", # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.82",  # .{2}
    gross_price_orig => "474.82",  # .{3}
    net_price        => 473.39554, # .{4}
    net_price_orig   => 473.39554, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 70]
  {
    base_size        => "0.02",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.78",  # .{2}
    gross_price_orig => "474.78",  # .{3}
    net_price        => 473.35566, # .{4}
    net_price_orig   => 473.35566, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 71]
  {
    base_size        => "0.819556", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "474.76",   # .{2}
    gross_price_orig => "474.76",   # .{3}
    net_price        => 473.33572,  # .{4}
    net_price_orig   => 473.33572,  # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 72]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.75",  # .{2}
    gross_price_orig => "474.75",  # .{3}
    net_price        => 473.32575, # .{4}
    net_price_orig   => 473.32575, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 73]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.72",  # .{2}
    gross_price_orig => "474.72",  # .{3}
    net_price        => 473.29584, # .{4}
    net_price_orig   => 473.29584, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 74]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.64",  # .{2}
    gross_price_orig => "474.64",  # .{3}
    net_price        => 473.21608, # .{4}
    net_price_orig   => 473.21608, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 75]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.63",  # .{2}
    gross_price_orig => "474.63",  # .{3}
    net_price        => 473.20611, # .{4}
    net_price_orig   => 473.20611, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 76]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.61",  # .{2}
    gross_price_orig => "474.61",  # .{3}
    net_price        => 473.18617, # .{4}
    net_price_orig   => 473.18617, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 77]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.59",  # .{2}
    gross_price_orig => "474.59",  # .{3}
    net_price        => 473.16623, # .{4}
    net_price_orig   => 473.16623, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 78]
  {
    base_size        => "342.28540332", # .{0}
    exchange         => "gdax",         # .{1}
    gross_price      => "474.56",       # .{2}
    gross_price_orig => "474.56",       # .{3}
    net_price        => 473.13632,      # .{4}
    net_price_orig   => 473.13632,      # .{5}
    quote_currency   => "USD",          # .{6}
  }, # [ 79]
  {
    base_size        => "50",      # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.55",  # .{2}
    gross_price_orig => "474.55",  # .{3}
    net_price        => 473.12635, # .{4}
    net_price_orig   => 473.12635, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 80]
  {
    base_size        => "50",      # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.53",  # .{2}
    gross_price_orig => "474.53",  # .{3}
    net_price        => 473.10641, # .{4}
    net_price_orig   => 473.10641, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 81]
  {
    base_size        => "0.15",   # .{0}
    exchange         => "gdax",   # .{1}
    gross_price      => "474.5",  # .{2}
    gross_price_orig => "474.5",  # .{3}
    net_price        => 473.0765, # .{4}
    net_price_orig   => 473.0765, # .{5}
    quote_currency   => "USD",    # .{6}
  }, # [ 82]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.49",  # .{2}
    gross_price_orig => "474.49",  # .{3}
    net_price        => 473.06653, # .{4}
    net_price_orig   => 473.06653, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 83]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.43",  # .{2}
    gross_price_orig => "474.43",  # .{3}
    net_price        => 473.00671, # .{4}
    net_price_orig   => 473.00671, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 84]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.41",  # .{2}
    gross_price_orig => "474.41",  # .{3}
    net_price        => 472.98677, # .{4}
    net_price_orig   => 472.98677, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 85]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.39",  # .{2}
    gross_price_orig => "474.39",  # .{3}
    net_price        => 472.96683, # .{4}
    net_price_orig   => 472.96683, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 86]
  {
    base_size        => "0.03802", # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "474.38",  # .{2}
    gross_price_orig => "474.38",  # .{3}
    net_price        => 472.95686, # .{4}
    net_price_orig   => 472.95686, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 87]
  {
    base_size        => "1.51759259", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 474.13836,    # .{2}
    gross_price_orig => 6588000,      # .{3}
    net_price        => 472.71594492, # .{4}
    net_price_orig   => 6568236,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 88]
  {
    base_size        => "7.62078951", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 472.19517,    # .{2}
    gross_price_orig => 6561000,      # .{3}
    net_price        => 470.77858449, # .{4}
    net_price_orig   => 6541317,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 89]
  {
    base_size        => "0.03049245", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 472.05123,    # .{2}
    gross_price_orig => 6559000,      # .{3}
    net_price        => 470.63507631, # .{4}
    net_price_orig   => 6539323,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 90]
  {
    base_size        => "0.03766687", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 471.4035,     # .{2}
    gross_price_orig => 6550000,      # .{3}
    net_price        => 469.9892895,  # .{4}
    net_price_orig   => 6530350,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 91]
  {
    base_size        => "0.06597116", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 469.10046,    # .{2}
    gross_price_orig => 6518000,      # .{3}
    net_price        => 467.69315862, # .{4}
    net_price_orig   => 6498446,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 92]
  {
    base_size        => "0.25738541", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 468.5247,     # .{2}
    gross_price_orig => 6510000,      # .{3}
    net_price        => 467.1191259,  # .{4}
    net_price_orig   => 6490470,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 93]
  {
    base_size        => "3.27641901", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 467.87697,    # .{2}
    gross_price_orig => 6501000,      # .{3}
    net_price        => 466.47333909, # .{4}
    net_price_orig   => 6481497,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 94]
  {
    base_size        => "38.02436462", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 467.805,       # .{2}
    gross_price_orig => 6500000,       # .{3}
    net_price        => 466.401585,    # .{4}
    net_price_orig   => 6480500,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 95]
  {
    base_size        => "0.06394531", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 467.15727,    # .{2}
    gross_price_orig => 6491000,      # .{3}
    net_price        => 465.75579819, # .{4}
    net_price_orig   => 6471527,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 96]
  {
    base_size        => "0.01688211", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 465.78984,    # .{2}
    gross_price_orig => 6472000,      # .{3}
    net_price        => 464.39247048, # .{4}
    net_price_orig   => 6452584,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 97]
  {
    base_size        => "0.46367852", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 465.6459,     # .{2}
    gross_price_orig => 6470000,      # .{3}
    net_price        => 464.2489623,  # .{4}
    net_price_orig   => 6450590,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 98]
  {
    base_size        => "3.05049566", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 464.63832,    # .{2}
    gross_price_orig => 6456000,      # .{3}
    net_price        => 463.24440504, # .{4}
    net_price_orig   => 6436632,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 99]
  {
    base_size        => "2.14585601", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 462.83907,    # .{2}
    gross_price_orig => 6431000,      # .{3}
    net_price        => 461.45055279, # .{4}
    net_price_orig   => 6411707,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [100]
  {
    base_size        => "0.07777259", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 462.69513,    # .{2}
    gross_price_orig => 6429000,      # .{3}
    net_price        => 461.30704461, # .{4}
    net_price_orig   => 6409713,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [101]
  {
    base_size        => "0.01555936", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 462.55119,    # .{2}
    gross_price_orig => 6427000,      # .{3}
    net_price        => 461.16353643, # .{4}
    net_price_orig   => 6407719,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [102]
  {
    base_size        => "1.55981906", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 461.39967,    # .{2}
    gross_price_orig => 6411000,      # .{3}
    net_price        => 460.01547099, # .{4}
    net_price_orig   => 6391767,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [103]
  {
    base_size        => "3.46211090", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 460.75194,    # .{2}
    gross_price_orig => 6402000,      # .{3}
    net_price        => 459.36968418, # .{4}
    net_price_orig   => 6382794,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [104]
  {
    base_size        => "7.86769703", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 460.608,      # .{2}
    gross_price_orig => 6400000,      # .{3}
    net_price        => 459.226176,   # .{4}
    net_price_orig   => 6380800,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [105]
  {
    base_size        => "0.15642109", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 460.10421,    # .{2}
    gross_price_orig => 6393000,      # .{3}
    net_price        => 458.72389737, # .{4}
    net_price_orig   => 6373821,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [106]
  {
    base_size        => "3.69616095", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 453.411,      # .{2}
    gross_price_orig => 6300000,      # .{3}
    net_price        => 452.050767,   # .{4}
    net_price_orig   => 6281100,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [107]
  {
    base_size        => "1.54749325", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 453.33903,    # .{2}
    gross_price_orig => 6299000,      # .{3}
    net_price        => 451.97901291, # .{4}
    net_price_orig   => 6280103,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [108]
  {
    base_size        => "3.18074781", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 452.33145,    # .{2}
    gross_price_orig => 6285000,      # .{3}
    net_price        => 450.97445565, # .{4}
    net_price_orig   => 6266145,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [109]
  {
    base_size        => "0.44778995", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 451.2519,     # .{2}
    gross_price_orig => 6270000,      # .{3}
    net_price        => 449.8981443,  # .{4}
    net_price_orig   => 6251190,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [110]
  {
    base_size        => "34.25933935", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 450.46023,     # .{2}
    gross_price_orig => 6259000,       # .{3}
    net_price        => 449.10884931,  # .{4}
    net_price_orig   => 6240223,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [111]
  {
    base_size        => "0.01070972", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 450.24432,    # .{2}
    gross_price_orig => 6256000,      # .{3}
    net_price        => 448.89358704, # .{4}
    net_price_orig   => 6237232,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [112]
  {
    base_size        => "7.47625164", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 449.88447,    # .{2}
    gross_price_orig => 6251000,      # .{3}
    net_price        => 448.53481659, # .{4}
    net_price_orig   => 6232247,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [113]
  {
    base_size        => "2.15114592", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 449.8125,     # .{2}
    gross_price_orig => 6250000,      # .{3}
    net_price        => 448.4630625,  # .{4}
    net_price_orig   => 6231250,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [114]
  {
    base_size        => "0.01000144", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 449.0928,     # .{2}
    gross_price_orig => 6240000,      # .{3}
    net_price        => 447.7455216,  # .{4}
    net_price_orig   => 6221280,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [115]
  {
    base_size        => "0.39423435", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 446.214,      # .{2}
    gross_price_orig => 6200000,      # .{3}
    net_price        => 444.875358,   # .{4}
    net_price_orig   => 6181400,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [116]
  {
    base_size        => "0.16078503", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 443.26323,    # .{2}
    gross_price_orig => 6159000,      # .{3}
    net_price        => 441.93344031, # .{4}
    net_price_orig   => 6140523,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [117]
  {
    base_size        => "0.01000130", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 442.83141,    # .{2}
    gross_price_orig => 6153000,      # .{3}
    net_price        => 441.50291577, # .{4}
    net_price_orig   => 6134541,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [118]
  {
    base_size        => "4.09551536", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 442.68747,    # .{2}
    gross_price_orig => 6151000,      # .{3}
    net_price        => 441.35940759, # .{4}
    net_price_orig   => 6132547,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [119]
  {
    base_size        => "0.00814332", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 441.8958,     # .{2}
    gross_price_orig => 6140000,      # .{3}
    net_price        => 440.5701126,  # .{4}
    net_price_orig   => 6121580,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [120]
  {
    base_size        => "1.70339052", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 440.4564,     # .{2}
    gross_price_orig => 6120000,      # .{3}
    net_price        => 439.1350308,  # .{4}
    net_price_orig   => 6101640,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [121]
  {
    base_size        => "29.44544414", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 439.95261,     # .{2}
    gross_price_orig => 6113000,       # .{3}
    net_price        => 438.63275217,  # .{4}
    net_price_orig   => 6094661,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [122]
  {
    base_size        => "3.08447070", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 439.7367,     # .{2}
    gross_price_orig => 6110000,      # .{3}
    net_price        => 438.4174899,  # .{4}
    net_price_orig   => 6091670,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [123]
  {
    base_size        => "0.01520882", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 439.08897,    # .{2}
    gross_price_orig => 6101000,      # .{3}
    net_price        => 437.77170309, # .{4}
    net_price_orig   => 6082697,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [124]
  {
    base_size        => "1.58577902", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 439.017,      # .{2}
    gross_price_orig => 6100000,      # .{3}
    net_price        => 437.699949,   # .{4}
    net_price_orig   => 6081700,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [125]
  {
    base_size        => "0.04924491", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 438.44124,    # .{2}
    gross_price_orig => 6092000,      # .{3}
    net_price        => 437.12591628, # .{4}
    net_price_orig   => 6073724,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [126]
  {
    base_size        => "1.20066206", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 437.86548,    # .{2}
    gross_price_orig => 6084000,      # .{3}
    net_price        => 436.55188356, # .{4}
    net_price_orig   => 6065748,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [127]
  {
    base_size        => "0.18268657", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 437.43366,    # .{2}
    gross_price_orig => 6078000,      # .{3}
    net_price        => 436.12135902, # .{4}
    net_price_orig   => 6059766,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [128]
  {
    base_size        => "0.22888230", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 437.21775,    # .{2}
    gross_price_orig => 6075000,      # .{3}
    net_price        => 435.90609675, # .{4}
    net_price_orig   => 6056775,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [129]
  {
    base_size        => "0.01000066", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 434.77077,    # .{2}
    gross_price_orig => 6041000,      # .{3}
    net_price        => 433.46645769, # .{4}
    net_price_orig   => 6022877,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [130]
  {
    base_size        => "0.12468828", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 432.89955,    # .{2}
    gross_price_orig => 6015000,      # .{3}
    net_price        => 431.60085135, # .{4}
    net_price_orig   => 5996955,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [131]
  {
    base_size        => "0.39221614", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 432.5397,     # .{2}
    gross_price_orig => 6010000,      # .{3}
    net_price        => 431.2420809,  # .{4}
    net_price_orig   => 5991970,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [132]
  {
    base_size        => "0.03017077", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 432.39576,    # .{2}
    gross_price_orig => 6008000,      # .{3}
    net_price        => 431.09857272, # .{4}
    net_price_orig   => 5989976,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [133]
  {
    base_size        => "1.83272243", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 431.96394,    # .{2}
    gross_price_orig => 6002000,      # .{3}
    net_price        => 430.66804818, # .{4}
    net_price_orig   => 5983994,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [134]
  {
    base_size        => "0.96573821", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 431.89197,    # .{2}
    gross_price_orig => 6001000,      # .{3}
    net_price        => 430.59629409, # .{4}
    net_price_orig   => 5982997,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [135]
  {
    base_size        => "43.08736133", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 431.82,        # .{2}
    gross_price_orig => 6000000,       # .{3}
    net_price        => 430.52454,     # .{4}
    net_price_orig   => 5982000,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [136]
  {
    base_size        => "0.10075567", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 428.58135,    # .{2}
    gross_price_orig => 5955000,      # .{3}
    net_price        => 427.29560595, # .{4}
    net_price_orig   => 5937135,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [137]
  {
    base_size        => "7.61018975", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 428.2215,     # .{2}
    gross_price_orig => 5950000,      # .{3}
    net_price        => 426.9368355,  # .{4}
    net_price_orig   => 5932150,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [138]
  {
    base_size        => "0.05901197", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 426.85407,    # .{2}
    gross_price_orig => 5931000,      # .{3}
    net_price        => 425.57350779, # .{4}
    net_price_orig   => 5913207,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [139]
  {
    base_size        => "2.03756373", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 424.623,      # .{2}
    gross_price_orig => 5900000,      # .{3}
    net_price        => 423.349131,   # .{4}
    net_price_orig   => 5882300,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [140]
  {
    base_size        => "0.33904052", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 424.55103,    # .{2}
    gross_price_orig => 5899000,      # .{3}
    net_price        => 423.27737691, # .{4}
    net_price_orig   => 5881303,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [141]
  {
    base_size        => "1.69952413", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 423.47148,    # .{2}
    gross_price_orig => 5884000,      # .{3}
    net_price        => 422.20106556, # .{4}
    net_price_orig   => 5866348,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [142]
  {
    base_size        => "0.80597871", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 422.4639,     # .{2}
    gross_price_orig => 5870000,      # .{3}
    net_price        => 421.1965083,  # .{4}
    net_price_orig   => 5852390,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [143]
  {
    base_size        => "0.34188034", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 421.0245,     # .{2}
    gross_price_orig => 5850000,      # .{3}
    net_price        => 419.7614265,  # .{4}
    net_price_orig   => 5832450,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [144]
  {
    base_size        => "0.24152414", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 417.426,      # .{2}
    gross_price_orig => 5800000,      # .{3}
    net_price        => 416.173722,   # .{4}
    net_price_orig   => 5782600,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [145]
  {
    base_size        => "1.44017270", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 413.8275,     # .{2}
    gross_price_orig => 5750000,      # .{3}
    net_price        => 412.5860175,  # .{4}
    net_price_orig   => 5732750,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [146]
  {
    base_size        => "6.41590719", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 410.229,      # .{2}
    gross_price_orig => 5700000,      # .{3}
    net_price        => 408.998313,   # .{4}
    net_price_orig   => 5682900,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [147]
  {
    base_size        => "0.52826202", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 408.71763,    # .{2}
    gross_price_orig => 5679000,      # .{3}
    net_price        => 407.49147711, # .{4}
    net_price_orig   => 5661963,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [148]
  {
    base_size        => "0.01692823", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 408.14187,    # .{2}
    gross_price_orig => 5671000,      # .{3}
    net_price        => 406.91744439, # .{4}
    net_price_orig   => 5653987,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [149]
  {
    base_size        => "0.14159292", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 406.6305,     # .{2}
    gross_price_orig => 5650000,      # .{3}
    net_price        => 405.4106085,  # .{4}
    net_price_orig   => 5633050,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [150]
  {
    base_size        => "0.01779993", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 404.32746,    # .{2}
    gross_price_orig => 5618000,      # .{3}
    net_price        => 403.11447762, # .{4}
    net_price_orig   => 5601146,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [151]
  {
    base_size        => "4.35554643", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 403.032,      # .{2}
    gross_price_orig => 5600000,      # .{3}
    net_price        => 401.822904,   # .{4}
    net_price_orig   => 5583200,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [152]
  {
    base_size        => "36.05466409", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 399.57744,     # .{2}
    gross_price_orig => 5552000,       # .{3}
    net_price        => 398.37870768,  # .{4}
    net_price_orig   => 5535344,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [153]
  {
    base_size        => "1.80108108", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 399.4335,     # .{2}
    gross_price_orig => 5550000,      # .{3}
    net_price        => 398.2351995,  # .{4}
    net_price_orig   => 5533350,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [154]
  {
    base_size        => "0.02756203", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 397.9941,     # .{2}
    gross_price_orig => 5530000,      # .{3}
    net_price        => 396.8001177,  # .{4}
    net_price_orig   => 5513410,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [155]
  {
    base_size        => "0.07645343", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 397.92213,    # .{2}
    gross_price_orig => 5529000,      # .{3}
    net_price        => 396.72836361, # .{4}
    net_price_orig   => 5512413,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [156]
  {
    base_size        => "14.14262327", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 395.835,       # .{2}
    gross_price_orig => 5500000,       # .{3}
    net_price        => 394.647495,    # .{4}
    net_price_orig   => 5483500,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [157]
  {
    base_size        => "0.18368846", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 391.80468,    # .{2}
    gross_price_orig => 5444000,      # .{3}
    net_price        => 390.62926596, # .{4}
    net_price_orig   => 5427668,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [158]
  {
    base_size        => "0.34970215", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 391.44483,    # .{2}
    gross_price_orig => 5439000,      # .{3}
    net_price        => 390.27049551, # .{4}
    net_price_orig   => 5422683,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [159]
  {
    base_size        => "0.34173741", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 388.638,      # .{2}
    gross_price_orig => 5400000,      # .{3}
    net_price        => 387.472086,   # .{4}
    net_price_orig   => 5383800,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [160]
  {
    base_size        => "0.08406301", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 387.1986,     # .{2}
    gross_price_orig => 5380000,      # .{3}
    net_price        => 386.0370042,  # .{4}
    net_price_orig   => 5363860,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [161]
  {
    base_size        => "0.01869159", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 385.0395,     # .{2}
    gross_price_orig => 5350000,      # .{3}
    net_price        => 383.8843815,  # .{4}
    net_price_orig   => 5333950,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [162]
  {
    base_size        => "0.62113831", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 382.44858,    # .{2}
    gross_price_orig => 5314000,      # .{3}
    net_price        => 381.30123426, # .{4}
    net_price_orig   => 5298058,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [163]
  {
    base_size        => "1.88359390", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 382.08873,    # .{2}
    gross_price_orig => 5309000,      # .{3}
    net_price        => 380.94246381, # .{4}
    net_price_orig   => 5293073,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [164]
  {
    base_size        => "31.32169019", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 381.441,       # .{2}
    gross_price_orig => 5300000,       # .{3}
    net_price        => 380.296677,    # .{4}
    net_price_orig   => 5284100,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [165]
  {
    base_size        => "0.04257137", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 379.64175,    # .{2}
    gross_price_orig => 5275000,      # .{3}
    net_price        => 378.50282475, # .{4}
    net_price_orig   => 5259175,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [166]
  {
    base_size        => "0.95075109", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 378.49023,    # .{2}
    gross_price_orig => 5259000,      # .{3}
    net_price        => 377.35475931, # .{4}
    net_price_orig   => 5243223,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [167]
  {
    base_size        => "0.20000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 377.8425,     # .{2}
    gross_price_orig => 5250000,      # .{3}
    net_price        => 376.7089725,  # .{4}
    net_price_orig   => 5234250,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [168]
  {
    base_size        => "0.19186493", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 375.10764,    # .{2}
    gross_price_orig => 5212000,      # .{3}
    net_price        => 373.98231708, # .{4}
    net_price_orig   => 5196364,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [169]
  {
    base_size        => "21.70008885", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 374.244,       # .{2}
    gross_price_orig => 5200000,       # .{3}
    net_price        => 373.121268,    # .{4}
    net_price_orig   => 5184400,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [170]
  {
    base_size        => "1.93050193", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 372.8046,     # .{2}
    gross_price_orig => 5180000,      # .{3}
    net_price        => 371.6861862,  # .{4}
    net_price_orig   => 5164460,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [171]
  {
    base_size        => "0.00975419", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 368.91822,    # .{2}
    gross_price_orig => 5126000,      # .{3}
    net_price        => 367.81146534, # .{4}
    net_price_orig   => 5110622,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [172]
  {
    base_size        => "0.30000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 368.84625,    # .{2}
    gross_price_orig => 5125000,      # .{3}
    net_price        => 367.73971125, # .{4}
    net_price_orig   => 5109625,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [173]
  {
    base_size        => "0.01706853", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 368.63034,    # .{2}
    gross_price_orig => 5122000,      # .{3}
    net_price        => 367.52444898, # .{4}
    net_price_orig   => 5106634,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [174]
  {
    base_size        => "0.11997648", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 367.11897,    # .{2}
    gross_price_orig => 5101000,      # .{3}
    net_price        => 366.01761309, # .{4}
    net_price_orig   => 5085697,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [175]
  {
    base_size        => "1.36426098", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 367.047,      # .{2}
    gross_price_orig => 5100000,      # .{3}
    net_price        => 365.945859,   # .{4}
    net_price_orig   => 5084700,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [176]
  {
    base_size        => "2.00039417", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 365.17578,    # .{2}
    gross_price_orig => 5074000,      # .{3}
    net_price        => 364.08025266, # .{4}
    net_price_orig   => 5058778,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [177]
  {
    base_size        => "0.98607551", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 365.03184,    # .{2}
    gross_price_orig => 5072000,      # .{3}
    net_price        => 363.93674448, # .{4}
    net_price_orig   => 5056784,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [178]
  {
    base_size        => "0.01980590", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 363.37653,    # .{2}
    gross_price_orig => 5049000,      # .{3}
    net_price        => 362.28640041, # .{4}
    net_price_orig   => 5033853,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [179]
  {
    base_size        => "16.97428400", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 359.85,        # .{2}
    gross_price_orig => 5000000,       # .{3}
    net_price        => 358.77045,     # .{4}
    net_price_orig   => 4985000,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [180]
  {
    base_size        => "0.10020040", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 359.1303,     # .{2}
    gross_price_orig => 4990000,      # .{3}
    net_price        => 358.0529091,  # .{4}
    net_price_orig   => 4975030,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [181]
  {
    base_size        => "0.20304569", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 354.45225,    # .{2}
    gross_price_orig => 4925000,      # .{3}
    net_price        => 353.38889325, # .{4}
    net_price_orig   => 4910225,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [182]
  {
    base_size        => "0.02040816", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 352.653,      # .{2}
    gross_price_orig => 4900000,      # .{3}
    net_price        => 351.595041,   # .{4}
    net_price_orig   => 4885300,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [183]
  {
    base_size        => "1.12573000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 345.456,      # .{2}
    gross_price_orig => 4800000,      # .{3}
    net_price        => 344.419632,   # .{4}
    net_price_orig   => 4785600,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [184]
  {
    base_size        => "0.85287521", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 342.00144,    # .{2}
    gross_price_orig => 4752000,      # .{3}
    net_price        => 340.97543568, # .{4}
    net_price_orig   => 4737744,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [185]
  {
    base_size        => "0.01265217", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 340.99386,    # .{2}
    gross_price_orig => 4738000,      # .{3}
    net_price        => 339.97087842, # .{4}
    net_price_orig   => 4723786,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [186]
  {
    base_size        => "0.00043884",  # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 340.626813,    # .{2}
    gross_price_orig => 4732900,       # .{3}
    net_price        => 339.604932561, # .{4}
    net_price_orig   => 4718701.3,     # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [187]
  {
    base_size        => "0.00715513",  # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 334.163907,    # .{2}
    gross_price_orig => 4643100,       # .{3}
    net_price        => 333.161415279, # .{4}
    net_price_orig   => 4629170.7,     # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [188]
  {
    base_size        => "0.18463950", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 333.79686,    # .{2}
    gross_price_orig => 4638000,      # .{3}
    net_price        => 332.79546942, # .{4}
    net_price_orig   => 4624086,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [189]
  {
    base_size        => "0.01098901", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 327.4635,     # .{2}
    gross_price_orig => 4550000,      # .{3}
    net_price        => 326.4811095,  # .{4}
    net_price_orig   => 4536350,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [190]
  {
    base_size        => "4.55555556", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 323.865,      # .{2}
    gross_price_orig => 4500000,      # .{3}
    net_price        => 322.893405,   # .{4}
    net_price_orig   => 4486500,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [191]
  {
    base_size        => "0.12376238", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 319.83468,    # .{2}
    gross_price_orig => 4444000,      # .{3}
    net_price        => 318.87517596, # .{4}
    net_price_orig   => 4430668,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [192]
  {
    base_size        => "0.91836735", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 317.3877,     # .{2}
    gross_price_orig => 4410000,      # .{3}
    net_price        => 316.4355369,  # .{4}
    net_price_orig   => 4396770,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [193]
  {
    base_size        => "0.45361760", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 317.31573,    # .{2}
    gross_price_orig => 4409000,      # .{3}
    net_price        => 316.36378281, # .{4}
    net_price_orig   => 4395773,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [194]
  {
    base_size        => "0.00023423",  # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 313.105485,    # .{2}
    gross_price_orig => 4350500,       # .{3}
    net_price        => 312.166168545, # .{4}
    net_price_orig   => 4337448.5,     # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [195]
  {
    base_size        => "0.32454628", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 309.471,      # .{2}
    gross_price_orig => 4300000,      # .{3}
    net_price        => 308.542587,   # .{4}
    net_price_orig   => 4287100,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [196]
  {
    base_size        => "0.11814745", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 304.57704,    # .{2}
    gross_price_orig => 4232000,      # .{3}
    net_price        => 303.66330888, # .{4}
    net_price_orig   => 4219304,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [197]
  {
    base_size        => "0.24189647", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 297.52398,    # .{2}
    gross_price_orig => 4134000,      # .{3}
    net_price        => 296.63140806, # .{4}
    net_price_orig   => 4121598,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [198]
  {
    base_size        => "2.64023793", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 296.73231,    # .{2}
    gross_price_orig => 4123000,      # .{3}
    net_price        => 295.84211307, # .{4}
    net_price_orig   => 4110631,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [199]
];

  my $all_sell_orders = [
  {
    base_size        => "29.29660603", # .{0}
    exchange         => "gdax",        # .{1}
    gross_price      => "476.88",      # .{2}
    gross_price_orig => "476.88",      # .{3}
    net_price        => 478.31064,     # .{4}
    net_price_orig   => 478.31064,     # .{5}
    quote_currency   => "USD",         # .{6}
  }, # [  0]
  {
    base_size        => "0.01991849", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "476.93",     # .{2}
    gross_price_orig => "476.93",     # .{3}
    net_price        => 478.36079,    # .{4}
    net_price_orig   => 478.36079,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [  1]
  {
    base_size        => "23",      # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "476.94",  # .{2}
    gross_price_orig => "476.94",  # .{3}
    net_price        => 478.37082, # .{4}
    net_price_orig   => 478.37082, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [  2]
  {
    base_size        => "27.33843225", # .{0}
    exchange         => "gdax",        # .{1}
    gross_price      => "476.95",      # .{2}
    gross_price_orig => "476.95",      # .{3}
    net_price        => 478.38085,     # .{4}
    net_price_orig   => 478.38085,     # .{5}
    quote_currency   => "USD",         # .{6}
  }, # [  3]
  {
    base_size        => "0.08071587", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "476.96",     # .{2}
    gross_price_orig => "476.96",     # .{3}
    net_price        => 478.39088,    # .{4}
    net_price_orig   => 478.39088,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [  4]
  {
    base_size        => "0.02410514", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "476.97",     # .{2}
    gross_price_orig => "476.97",     # .{3}
    net_price        => 478.40091,    # .{4}
    net_price_orig   => 478.40091,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [  5]
  {
    base_size        => "2.01991122", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "476.98",     # .{2}
    gross_price_orig => "476.98",     # .{3}
    net_price        => 478.41094,    # .{4}
    net_price_orig   => 478.41094,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [  6]
  {
    base_size        => "0.08071441", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "476.99",     # .{2}
    gross_price_orig => "476.99",     # .{3}
    net_price        => 478.42097,    # .{4}
    net_price_orig   => 478.42097,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [  7]
  {
    base_size        => "0.04087573", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "477",        # .{2}
    gross_price_orig => "477",        # .{3}
    net_price        => 478.431,      # .{4}
    net_price_orig   => 478.431,      # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [  8]
  {
    base_size        => "0.01781454", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "477.01",     # .{2}
    gross_price_orig => "477.01",     # .{3}
    net_price        => 478.44103,    # .{4}
    net_price_orig   => 478.44103,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [  9]
  {
    base_size        => "0.01152531", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "477.02",     # .{2}
    gross_price_orig => "477.02",     # .{3}
    net_price        => 478.45106,    # .{4}
    net_price_orig   => 478.45106,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [ 10]
  {
    base_size        => "0.01781741", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "477.03",     # .{2}
    gross_price_orig => "477.03",     # .{3}
    net_price        => 478.46109,    # .{4}
    net_price_orig   => 478.46109,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [ 11]
  {
    base_size        => "0.02620255", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "477.04",     # .{2}
    gross_price_orig => "477.04",     # .{3}
    net_price        => 478.47112,    # .{4}
    net_price_orig   => 478.47112,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [ 12]
  {
    base_size        => "0.03248779", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "477.05",     # .{2}
    gross_price_orig => "477.05",     # .{3}
    net_price        => 478.48115,    # .{4}
    net_price_orig   => 478.48115,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [ 13]
  {
    base_size        => "0.97",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.06",  # .{2}
    gross_price_orig => "477.06",  # .{3}
    net_price        => 478.49118, # .{4}
    net_price_orig   => 478.49118, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 14]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.18",  # .{2}
    gross_price_orig => "477.18",  # .{3}
    net_price        => 478.61154, # .{4}
    net_price_orig   => 478.61154, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 15]
  {
    base_size        => "0.331761", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "477.26",   # .{2}
    gross_price_orig => "477.26",   # .{3}
    net_price        => 478.69178,  # .{4}
    net_price_orig   => 478.69178,  # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 16]
  {
    base_size        => "0.014",   # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.28",  # .{2}
    gross_price_orig => "477.28",  # .{3}
    net_price        => 478.71184, # .{4}
    net_price_orig   => 478.71184, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 17]
  {
    base_size        => "11.4",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.34",  # .{2}
    gross_price_orig => "477.34",  # .{3}
    net_price        => 478.77202, # .{4}
    net_price_orig   => 478.77202, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 18]
  {
    base_size        => "0.105899", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "477.36",   # .{2}
    gross_price_orig => "477.36",   # .{3}
    net_price        => 478.79208,  # .{4}
    net_price_orig   => 478.79208,  # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 19]
  {
    base_size        => "0.211766", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "477.42",   # .{2}
    gross_price_orig => "477.42",   # .{3}
    net_price        => 478.85226,  # .{4}
    net_price_orig   => 478.85226,  # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 20]
  {
    base_size        => "0.317663", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "477.43",   # .{2}
    gross_price_orig => "477.43",   # .{3}
    net_price        => 478.86229,  # .{4}
    net_price_orig   => 478.86229,  # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 21]
  {
    base_size        => "0.105903", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "477.45",   # .{2}
    gross_price_orig => "477.45",   # .{3}
    net_price        => 478.88235,  # .{4}
    net_price_orig   => 478.88235,  # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 22]
  {
    base_size        => "0.406872", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "477.48",   # .{2}
    gross_price_orig => "477.48",   # .{3}
    net_price        => 478.91244,  # .{4}
    net_price_orig   => 478.91244,  # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 23]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.51",  # .{2}
    gross_price_orig => "477.51",  # .{3}
    net_price        => 478.94253, # .{4}
    net_price_orig   => 478.94253, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 24]
  {
    base_size        => "8.2",     # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.53",  # .{2}
    gross_price_orig => "477.53",  # .{3}
    net_price        => 478.96259, # .{4}
    net_price_orig   => 478.96259, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 25]
  {
    base_size        => "0.533445", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "477.6",    # .{2}
    gross_price_orig => "477.6",    # .{3}
    net_price        => 479.0328,   # .{4}
    net_price_orig   => 479.0328,   # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 26]
  {
    base_size        => "10",      # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.63",  # .{2}
    gross_price_orig => "477.63",  # .{3}
    net_price        => 479.06289, # .{4}
    net_price_orig   => 479.06289, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 27]
  {
    base_size        => "6",       # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.64",  # .{2}
    gross_price_orig => "477.64",  # .{3}
    net_price        => 479.07292, # .{4}
    net_price_orig   => 479.07292, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 28]
  {
    base_size        => "15",      # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.69",  # .{2}
    gross_price_orig => "477.69",  # .{3}
    net_price        => 479.12307, # .{4}
    net_price_orig   => 479.12307, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 29]
  {
    base_size        => "8.1",     # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.73",  # .{2}
    gross_price_orig => "477.73",  # .{3}
    net_price        => 479.16319, # .{4}
    net_price_orig   => 479.16319, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 30]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.76",  # .{2}
    gross_price_orig => "477.76",  # .{3}
    net_price        => 479.19328, # .{4}
    net_price_orig   => 479.19328, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 31]
  {
    base_size        => "10.24998", # .{0}
    exchange         => "gdax",     # .{1}
    gross_price      => "477.77",   # .{2}
    gross_price_orig => "477.77",   # .{3}
    net_price        => 479.20331,  # .{4}
    net_price_orig   => 479.20331,  # .{5}
    quote_currency   => "USD",      # .{6}
  }, # [ 32]
  {
    base_size        => "114",     # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.79",  # .{2}
    gross_price_orig => "477.79",  # .{3}
    net_price        => 479.22337, # .{4}
    net_price_orig   => 479.22337, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 33]
  {
    base_size        => "50",     # .{0}
    exchange         => "gdax",   # .{1}
    gross_price      => "477.8",  # .{2}
    gross_price_orig => "477.8",  # .{3}
    net_price        => 479.2334, # .{4}
    net_price_orig   => 479.2334, # .{5}
    quote_currency   => "USD",    # .{6}
  }, # [ 34]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.81",  # .{2}
    gross_price_orig => "477.81",  # .{3}
    net_price        => 479.24343, # .{4}
    net_price_orig   => 479.24343, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 35]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.83",  # .{2}
    gross_price_orig => "477.83",  # .{3}
    net_price        => 479.26349, # .{4}
    net_price_orig   => 479.26349, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 36]
  {
    base_size        => "17.756",  # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.84",  # .{2}
    gross_price_orig => "477.84",  # .{3}
    net_price        => 479.27352, # .{4}
    net_price_orig   => 479.27352, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 37]
  {
    base_size        => "3.295",  # .{0}
    exchange         => "gdax",   # .{1}
    gross_price      => "477.9",  # .{2}
    gross_price_orig => "477.9",  # .{3}
    net_price        => 479.3337, # .{4}
    net_price_orig   => 479.3337, # .{5}
    quote_currency   => "USD",    # .{6}
  }, # [ 38]
  {
    base_size        => "11.2",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.93",  # .{2}
    gross_price_orig => "477.93",  # .{3}
    net_price        => 479.36379, # .{4}
    net_price_orig   => 479.36379, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 39]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "477.96",  # .{2}
    gross_price_orig => "477.96",  # .{3}
    net_price        => 479.39388, # .{4}
    net_price_orig   => 479.39388, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 40]
  {
    base_size        => "186.3655397", # .{0}
    exchange         => "gdax",        # .{1}
    gross_price      => "478",         # .{2}
    gross_price_orig => "478",         # .{3}
    net_price        => 479.434,       # .{4}
    net_price_orig   => 479.434,       # .{5}
    quote_currency   => "USD",         # .{6}
  }, # [ 41]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "478.01",  # .{2}
    gross_price_orig => "478.01",  # .{3}
    net_price        => 479.44403, # .{4}
    net_price_orig   => 479.44403, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 42]
  {
    base_size        => "0.093",   # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "478.14",  # .{2}
    gross_price_orig => "478.14",  # .{3}
    net_price        => 479.57442, # .{4}
    net_price_orig   => 479.57442, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 43]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "478.18",  # .{2}
    gross_price_orig => "478.18",  # .{3}
    net_price        => 479.61454, # .{4}
    net_price_orig   => 479.61454, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 44]
  {
    base_size        => "7.33653289", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "478.21",     # .{2}
    gross_price_orig => "478.21",     # .{3}
    net_price        => 479.64463,    # .{4}
    net_price_orig   => 479.64463,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [ 45]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "478.32",  # .{2}
    gross_price_orig => "478.32",  # .{3}
    net_price        => 479.75496, # .{4}
    net_price_orig   => 479.75496, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 46]
  {
    base_size        => "6.22",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "478.41",  # .{2}
    gross_price_orig => "478.41",  # .{3}
    net_price        => 479.84523, # .{4}
    net_price_orig   => 479.84523, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 47]
  {
    base_size        => "0.89111563", # .{0}
    exchange         => "gdax",       # .{1}
    gross_price      => "478.42",     # .{2}
    gross_price_orig => "478.42",     # .{3}
    net_price        => 479.85526,    # .{4}
    net_price_orig   => 479.85526,    # .{5}
    quote_currency   => "USD",        # .{6}
  }, # [ 48]
  {
    base_size        => "0.01",    # .{0}
    exchange         => "gdax",    # .{1}
    gross_price      => "478.45",  # .{2}
    gross_price_orig => "478.45",  # .{3}
    net_price        => 479.88535, # .{4}
    net_price_orig   => 479.88535, # .{5}
    quote_currency   => "USD",     # .{6}
  }, # [ 49]
  {
    base_size        => "0.08000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 495.27357,    # .{2}
    gross_price_orig => "6897000",    # .{3}
    net_price        => 496.75939071, # .{4}
    net_price_orig   => 6917691,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 50]
  {
    base_size        => "3.15403871", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 495.489,      # .{2}
    gross_price_orig => 6900000,      # .{3}
    net_price        => 496.975467,   # .{4}
    net_price_orig   => 6920700,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 51]
  {
    base_size        => "0.49998034", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 496.2071,     # .{2}
    gross_price_orig => 6910000,      # .{3}
    net_price        => 497.6957213,  # .{4}
    net_price_orig   => 6930730,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 52]
  {
    base_size        => "0.03800180", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 496.56615,    # .{2}
    gross_price_orig => 6915000,      # .{3}
    net_price        => 498.05584845, # .{4}
    net_price_orig   => 6935745,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 53]
  {
    base_size        => "0.27532029", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 498.3614,     # .{2}
    gross_price_orig => 6940000,      # .{3}
    net_price        => 499.8564842,  # .{4}
    net_price_orig   => 6960820,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 54]
  {
    base_size        => "0.05009710", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 498.50502,    # .{2}
    gross_price_orig => 6942000,      # .{3}
    net_price        => 500.00053506, # .{4}
    net_price_orig   => 6962826,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 55]
  {
    base_size        => "20.40000000", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 498.93588,     # .{2}
    gross_price_orig => 6948000,       # .{3}
    net_price        => 500.43268764,  # .{4}
    net_price_orig   => 6968844,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 56]
  {
    base_size        => "0.02426358", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 499.0795,     # .{2}
    gross_price_orig => 6950000,      # .{3}
    net_price        => 500.5767385,  # .{4}
    net_price_orig   => 6970850,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 57]
  {
    base_size        => "0.58103678", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 499.72579,    # .{2}
    gross_price_orig => 6959000,      # .{3}
    net_price        => 501.22496737, # .{4}
    net_price_orig   => 6979877,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 58]
  {
    base_size        => "4.36390000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 502.59819,    # .{2}
    gross_price_orig => 6999000,      # .{3}
    net_price        => 504.10598457, # .{4}
    net_price_orig   => 7019997,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 59]
  {
    base_size        => "22.02314138", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 502.67,        # .{2}
    gross_price_orig => 7000000,       # .{3}
    net_price        => 504.17801,     # .{4}
    net_price_orig   => 7021000,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 60]
  {
    base_size        => "90.30000000", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 502.81362,     # .{2}
    gross_price_orig => 7002000,       # .{3}
    net_price        => 504.32206086,  # .{4}
    net_price_orig   => 7023006,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 61]
  {
    base_size        => "0.62773172", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 503.45991,    # .{2}
    gross_price_orig => 7011000,      # .{3}
    net_price        => 504.97028973, # .{4}
    net_price_orig   => 7032033,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 62]
  {
    base_size        => "0.10013380", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 505.5424,     # .{2}
    gross_price_orig => 7040000,      # .{3}
    net_price        => 507.0590272,  # .{4}
    net_price_orig   => 7061120,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 63]
  {
    base_size        => "0.66616404", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 505.90145,    # .{2}
    gross_price_orig => 7045000,      # .{3}
    net_price        => 507.41915435, # .{4}
    net_price_orig   => 7066135,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 64]
  {
    base_size        => "0.15217198", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 508.84566,    # .{2}
    gross_price_orig => 7086000,      # .{3}
    net_price        => 510.37219698, # .{4}
    net_price_orig   => 7107258,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 65]
  {
    base_size        => "0.01010000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 509.42014,    # .{2}
    gross_price_orig => 7094000,      # .{3}
    net_price        => 510.94840042, # .{4}
    net_price_orig   => 7115282,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 66]
  {
    base_size        => "0.01990157", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 510.99996,    # .{2}
    gross_price_orig => 7116000,      # .{3}
    net_price        => 512.53295988, # .{4}
    net_price_orig   => 7137348,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 67]
  {
    base_size        => "29.53342512", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 511.14358,     # .{2}
    gross_price_orig => 7118000,       # .{3}
    net_price        => 512.67701074,  # .{4}
    net_price_orig   => 7139354,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 68]
  {
    base_size        => "0.07394199", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 512.0053,     # .{2}
    gross_price_orig => 7130000,      # .{3}
    net_price        => 513.5413159,  # .{4}
    net_price_orig   => 7151390,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 69]
  {
    base_size        => "1.59577244", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 512.43616,    # .{2}
    gross_price_orig => 7136000,      # .{3}
    net_price        => 513.97346848, # .{4}
    net_price_orig   => 7157408,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 70]
  {
    base_size        => "0.13000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 513.4415,     # .{2}
    gross_price_orig => 7150000,      # .{3}
    net_price        => 514.9818245,  # .{4}
    net_price_orig   => 7171450,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 71]
  {
    base_size        => "0.36469885", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 514.08779,    # .{2}
    gross_price_orig => 7159000,      # .{3}
    net_price        => 515.63005337, # .{4}
    net_price_orig   => 7180477,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 72]
  {
    base_size        => "0.14000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 515.38037,    # .{2}
    gross_price_orig => 7177000,      # .{3}
    net_price        => 516.92651111, # .{4}
    net_price_orig   => 7198531,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 73]
  {
    base_size        => "0.05000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 516.96019,    # .{2}
    gross_price_orig => 7199000,      # .{3}
    net_price        => 518.51107057, # .{4}
    net_price_orig   => 7220597,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 74]
  {
    base_size        => "2.38237676", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 517.032,      # .{2}
    gross_price_orig => 7200000,      # .{3}
    net_price        => 518.583096,   # .{4}
    net_price_orig   => 7221600,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 75]
  {
    base_size        => "0.02000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 518.10915,    # .{2}
    gross_price_orig => 7215000,      # .{3}
    net_price        => 519.66347745, # .{4}
    net_price_orig   => 7236645,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 76]
  {
    base_size        => "7.14183381", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 518.32458,    # .{2}
    gross_price_orig => 7218000,      # .{3}
    net_price        => 519.87955374, # .{4}
    net_price_orig   => 7239654,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 77]
  {
    base_size        => "5.32392569", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 518.4682,     # .{2}
    gross_price_orig => 7220000,      # .{3}
    net_price        => 520.0236046,  # .{4}
    net_price_orig   => 7241660,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 78]
  {
    base_size        => "0.46649373", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 520.6225,     # .{2}
    gross_price_orig => 7250000,      # .{3}
    net_price        => 522.1843675,  # .{4}
    net_price_orig   => 7271750,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 79]
  {
    base_size        => "3.17188988", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 524.213,      # .{2}
    gross_price_orig => 7300000,      # .{3}
    net_price        => 525.785639,   # .{4}
    net_price_orig   => 7321900,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 80]
  {
    base_size        => "0.01173189", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 524.35662,    # .{2}
    gross_price_orig => 7302000,      # .{3}
    net_price        => 525.92968986, # .{4}
    net_price_orig   => 7323906,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 81]
  {
    base_size        => "0.82823988", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 525.79282,    # .{2}
    gross_price_orig => 7322000,      # .{3}
    net_price        => 527.37019846, # .{4}
    net_price_orig   => 7343966,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 82]
  {
    base_size        => "0.10000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 526.58273,    # .{2}
    gross_price_orig => 7333000,      # .{3}
    net_price        => 528.16247819, # .{4}
    net_price_orig   => 7354999,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 83]
  {
    base_size        => "0.01362069", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 529.81418,    # .{2}
    gross_price_orig => 7378000,      # .{3}
    net_price        => 531.40362254, # .{4}
    net_price_orig   => 7400134,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 84]
  {
    base_size        => "0.39247429", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 529.88599,    # .{2}
    gross_price_orig => 7379000,      # .{3}
    net_price        => 531.47564797, # .{4}
    net_price_orig   => 7401137,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 85]
  {
    base_size        => "0.54321387", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 531.394,      # .{2}
    gross_price_orig => 7400000,      # .{3}
    net_price        => 532.988182,   # .{4}
    net_price_orig   => 7422200,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 86]
  {
    base_size        => "0.20948768", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 531.53762,    # .{2}
    gross_price_orig => 7402000,      # .{3}
    net_price        => 533.13223286, # .{4}
    net_price_orig   => 7424206,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 87]
  {
    base_size        => "97.00000000", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 532.97382,     # .{2}
    gross_price_orig => 7422000,       # .{3}
    net_price        => 534.57274146,  # .{4}
    net_price_orig   => 7444266,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 88]
  {
    base_size        => "34.99500000", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 536.4207,      # .{2}
    gross_price_orig => 7470000,       # .{3}
    net_price        => 538.0299621,   # .{4}
    net_price_orig   => 7492410,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 89]
  {
    base_size        => "0.26500000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 537.8569,     # .{2}
    gross_price_orig => 7490000,      # .{3}
    net_price        => 539.4704707,  # .{4}
    net_price_orig   => 7512470,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 90]
  {
    base_size        => "38.86188084", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 538.575,       # .{2}
    gross_price_orig => 7500000,       # .{3}
    net_price        => 540.190725,    # .{4}
    net_price_orig   => 7522500,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [ 91]
  {
    base_size        => "0.02610803", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 543.6017,     # .{2}
    gross_price_orig => 7570000,      # .{3}
    net_price        => 545.2325051,  # .{4}
    net_price_orig   => 7592710,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 92]
  {
    base_size        => "0.16211000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 544.53523,    # .{2}
    gross_price_orig => 7583000,      # .{3}
    net_price        => 546.16883569, # .{4}
    net_price_orig   => 7605749,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 93]
  {
    base_size        => "0.10000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 545.0379,     # .{2}
    gross_price_orig => 7590000,      # .{3}
    net_price        => 546.6730137,  # .{4}
    net_price_orig   => 7612770,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 94]
  {
    base_size        => "6.66899117", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 545.756,      # .{2}
    gross_price_orig => 7600000,      # .{3}
    net_price        => 547.393268,   # .{4}
    net_price_orig   => 7622800,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 95]
  {
    base_size        => "0.01333333", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 549.3465,     # .{2}
    gross_price_orig => 7650000,      # .{3}
    net_price        => 550.9945395,  # .{4}
    net_price_orig   => 7672950,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 96]
  {
    base_size        => "0.15607752", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 552.14709,    # .{2}
    gross_price_orig => 7689000,      # .{3}
    net_price        => 553.80353127, # .{4}
    net_price_orig   => 7712067,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 97]
  {
    base_size        => "0.05940149", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 552.937,      # .{2}
    gross_price_orig => 7700000,      # .{3}
    net_price        => 554.595811,   # .{4}
    net_price_orig   => 7723100,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 98]
  {
    base_size        => "0.01293150", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 553.6551,     # .{2}
    gross_price_orig => 7710000,      # .{3}
    net_price        => 555.3160653,  # .{4}
    net_price_orig   => 7733130,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [ 99]
  {
    base_size        => "0.07207949", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 555.0913,     # .{2}
    gross_price_orig => 7730000,      # .{3}
    net_price        => 556.7565739,  # .{4}
    net_price_orig   => 7753190,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [100]
  {
    base_size        => "17.68300000", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 556.5275,      # .{2}
    gross_price_orig => 7750000,       # .{3}
    net_price        => 558.1970825,   # .{4}
    net_price_orig   => 7773250,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [101]
  {
    base_size        => "0.10000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 557.03017,    # .{2}
    gross_price_orig => 7757000,      # .{3}
    net_price        => 558.70126051, # .{4}
    net_price_orig   => 7780271,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [102]
  {
    base_size        => "0.20077097", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 558.39456,    # .{2}
    gross_price_orig => 7776000,      # .{3}
    net_price        => 560.06974368, # .{4}
    net_price_orig   => 7799328,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [103]
  {
    base_size        => "0.40000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 559.32809,    # .{2}
    gross_price_orig => 7789000,      # .{3}
    net_price        => 561.00607427, # .{4}
    net_price_orig   => 7812367,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [104]
  {
    base_size        => "0.71003641", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 559.54352,    # .{2}
    gross_price_orig => 7792000,      # .{3}
    net_price        => 561.22215056, # .{4}
    net_price_orig   => 7815376,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [105]
  {
    base_size        => "0.03125221", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 560.04619,    # .{2}
    gross_price_orig => 7799000,      # .{3}
    net_price        => 561.72632857, # .{4}
    net_price_orig   => 7822397,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [106]
  {
    base_size        => "0.26618543", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 560.118,      # .{2}
    gross_price_orig => 7800000,      # .{3}
    net_price        => 561.798354,   # .{4}
    net_price_orig   => 7823400,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [107]
  {
    base_size        => "1.00000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 560.8361,     # .{2}
    gross_price_orig => 7810000,      # .{3}
    net_price        => 562.5186083,  # .{4}
    net_price_orig   => 7833430,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [108]
  {
    base_size        => "0.12306913", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 563.7085,     # .{2}
    gross_price_orig => 7850000,      # .{3}
    net_price        => 565.3996255,  # .{4}
    net_price_orig   => 7873550,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [109]
  {
    base_size        => "0.40072820", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 563.85212,    # .{2}
    gross_price_orig => 7852000,      # .{3}
    net_price        => 565.54367636, # .{4}
    net_price_orig   => 7875556,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [110]
  {
    base_size        => "0.34602294", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 564.06755,    # .{2}
    gross_price_orig => 7855000,      # .{3}
    net_price        => 565.75975265, # .{4}
    net_price_orig   => 7878565,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [111]
  {
    base_size        => "0.02209586", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 564.21117,    # .{2}
    gross_price_orig => 7857000,      # .{3}
    net_price        => 565.90380351, # .{4}
    net_price_orig   => 7880571,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [112]
  {
    base_size        => "3.03162760", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 565.93461,    # .{2}
    gross_price_orig => 7881000,      # .{3}
    net_price        => 567.63241383, # .{4}
    net_price_orig   => 7904643,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [113]
  {
    base_size        => "0.52319883", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 566.36547,    # .{2}
    gross_price_orig => 7887000,      # .{3}
    net_price        => 568.06456641, # .{4}
    net_price_orig   => 7910661,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [114]
  {
    base_size        => "0.05671558", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 566.65271,    # .{2}
    gross_price_orig => 7891000,      # .{3}
    net_price        => 568.35266813, # .{4}
    net_price_orig   => 7914673,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [115]
  {
    base_size        => "0.06000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 567.299,      # .{2}
    gross_price_orig => 7900000,      # .{3}
    net_price        => 569.000897,   # .{4}
    net_price_orig   => 7923700,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [116]
  {
    base_size        => "0.13218770", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 567.44262,    # .{2}
    gross_price_orig => 7902000,      # .{3}
    net_price        => 569.14494786, # .{4}
    net_price_orig   => 7925706,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [117]
  {
    base_size        => "0.01278860", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 568.30434,    # .{2}
    gross_price_orig => 7914000,      # .{3}
    net_price        => 570.00925302, # .{4}
    net_price_orig   => 7937742,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [118]
  {
    base_size        => "0.20024498", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 568.51977,    # .{2}
    gross_price_orig => 7917000,      # .{3}
    net_price        => 570.22532931, # .{4}
    net_price_orig   => 7940751,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [119]
  {
    base_size        => "0.63127238", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 570.53045,    # .{2}
    gross_price_orig => 7945000,      # .{3}
    net_price        => 572.24204135, # .{4}
    net_price_orig   => 7968835,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [120]
  {
    base_size        => "0.01620010", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 570.67407,    # .{2}
    gross_price_orig => 7947000,      # .{3}
    net_price        => 572.38609221, # .{4}
    net_price_orig   => 7970841,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [121]
  {
    base_size        => "0.01258178", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 572.68475,    # .{2}
    gross_price_orig => 7975000,      # .{3}
    net_price        => 574.40280425, # .{4}
    net_price_orig   => 7998925,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [122]
  {
    base_size        => "0.02576607", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 573.61828,    # .{2}
    gross_price_orig => 7988000,      # .{3}
    net_price        => 575.33913484, # .{4}
    net_price_orig   => 8011964,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [123]
  {
    base_size        => "0.01897971", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 573.69009,    # .{2}
    gross_price_orig => 7989000,      # .{3}
    net_price        => 575.41116027, # .{4}
    net_price_orig   => 8012967,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [124]
  {
    base_size        => "20.65917991", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 574.48,        # .{2}
    gross_price_orig => 8000000,       # .{3}
    net_price        => 576.20344,     # .{4}
    net_price_orig   => 8024000,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [125]
  {
    base_size        => "0.01589998", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 575.1981,     # .{2}
    gross_price_orig => 8010000,      # .{3}
    net_price        => 576.9236943,  # .{4}
    net_price_orig   => 8034030,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [126]
  {
    base_size        => "0.01303460", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 575.84439,    # .{2}
    gross_price_orig => 8019000,      # .{3}
    net_price        => 577.57192317, # .{4}
    net_price_orig   => 8043057,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [127]
  {
    base_size        => "0.01265822", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 578.0705,     # .{2}
    gross_price_orig => 8050000,      # .{3}
    net_price        => 579.8047115,  # .{4}
    net_price_orig   => 8074150,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [128]
  {
    base_size        => "0.57239925", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 578.93222,    # .{2}
    gross_price_orig => 8062000,      # .{3}
    net_price        => 580.66901666, # .{4}
    net_price_orig   => 8086186,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [129]
  {
    base_size        => "0.40018703", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 581.661,      # .{2}
    gross_price_orig => 8100000,      # .{3}
    net_price        => 583.405983,   # .{4}
    net_price_orig   => 8124300,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [130]
  {
    base_size        => "0.24627385", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 581.94824,    # .{2}
    gross_price_orig => 8104000,      # .{3}
    net_price        => 583.69408472, # .{4}
    net_price_orig   => 8128312,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [131]
  {
    base_size        => "0.10014166", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 582.30729,    # .{2}
    gross_price_orig => 8109000,      # .{3}
    net_price        => 584.05421187, # .{4}
    net_price_orig   => 8133327,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [132]
  {
    base_size        => "0.33740678", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 583.38444,    # .{2}
    gross_price_orig => 8124000,      # .{3}
    net_price        => 585.13459332, # .{4}
    net_price_orig   => 8148372,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [133]
  {
    base_size        => "0.40194845", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 587.19037,    # .{2}
    gross_price_orig => 8177000,      # .{3}
    net_price        => 588.95194111, # .{4}
    net_price_orig   => 8201531,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [134]
  {
    base_size        => "0.01000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 587.62123,    # .{2}
    gross_price_orig => 8183000,      # .{3}
    net_price        => 589.38409369, # .{4}
    net_price_orig   => 8207549,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [135]
  {
    base_size        => "0.01242848", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 588.26752,    # .{2}
    gross_price_orig => 8192000,      # .{3}
    net_price        => 590.03232256, # .{4}
    net_price_orig   => 8216576,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [136]
  {
    base_size        => "17.11077615", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 588.842,       # .{2}
    gross_price_orig => 8200000,       # .{3}
    net_price        => 590.608526,    # .{4}
    net_price_orig   => 8224600,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [137]
  {
    base_size        => "0.04000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 589.5601,     # .{2}
    gross_price_orig => 8210000,      # .{3}
    net_price        => 591.3287803,  # .{4}
    net_price_orig   => 8234630,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [138]
  {
    base_size        => "0.29268292", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 590.70906,    # .{2}
    gross_price_orig => 8226000,      # .{3}
    net_price        => 592.48118718, # .{4}
    net_price_orig   => 8250678,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [139]
  {
    base_size        => "0.14962785", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 592.36069,    # .{2}
    gross_price_orig => 8249000,      # .{3}
    net_price        => 594.13777207, # .{4}
    net_price_orig   => 8273747,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [140]
  {
    base_size        => "6.91128330", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 592.4325,     # .{2}
    gross_price_orig => 8250000,      # .{3}
    net_price        => 594.2097975,  # .{4}
    net_price_orig   => 8274750,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [141]
  {
    base_size        => "0.25297242", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 592.79155,    # .{2}
    gross_price_orig => 8255000,      # .{3}
    net_price        => 594.56992465, # .{4}
    net_price_orig   => 8279765,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [142]
  {
    base_size        => "7.60770000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 593.29422,    # .{2}
    gross_price_orig => 8262000,      # .{3}
    net_price        => 595.07410266, # .{4}
    net_price_orig   => 8286786,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [143]
  {
    base_size        => "0.45248022", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 593.8687,     # .{2}
    gross_price_orig => 8270000,      # .{3}
    net_price        => 595.6503061,  # .{4}
    net_price_orig   => 8294810,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [144]
  {
    base_size        => "0.81330292", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 596.023,      # .{2}
    gross_price_orig => 8300000,      # .{3}
    net_price        => 597.811069,   # .{4}
    net_price_orig   => 8324900,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [145]
  {
    base_size        => "0.24920206", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 596.09481,    # .{2}
    gross_price_orig => 8301000,      # .{3}
    net_price        => 597.88309443, # .{4}
    net_price_orig   => 8325903,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [146]
  {
    base_size        => "0.01219512", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 599.6135,     # .{2}
    gross_price_orig => 8350000,      # .{3}
    net_price        => 601.4123405,  # .{4}
    net_price_orig   => 8375050,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [147]
  {
    base_size        => "0.04400000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 600.25979,    # .{2}
    gross_price_orig => 8359000,      # .{3}
    net_price        => 602.06056937, # .{4}
    net_price_orig   => 8384077,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [148]
  {
    base_size        => "1.31578947", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 600.3316,     # .{2}
    gross_price_orig => 8360000,      # .{3}
    net_price        => 602.1325948,  # .{4}
    net_price_orig   => 8385080,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [149]
  {
    base_size        => "0.01213592", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 601.0497,     # .{2}
    gross_price_orig => 8370000,      # .{3}
    net_price        => 602.8528491,  # .{4}
    net_price_orig   => 8395110,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [150]
  {
    base_size        => "0.12953367", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 601.40875,    # .{2}
    gross_price_orig => 8375000,      # .{3}
    net_price        => 603.21297625, # .{4}
    net_price_orig   => 8400125,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [151]
  {
    base_size        => "0.02391066", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 602.91676,    # .{2}
    gross_price_orig => 8396000,      # .{3}
    net_price        => 604.72551028, # .{4}
    net_price_orig   => 8421188,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [152]
  {
    base_size        => "4.89045070", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 603.204,      # .{2}
    gross_price_orig => 8400000,      # .{3}
    net_price        => 605.013612,   # .{4}
    net_price_orig   => 8425200,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [153]
  {
    base_size        => "0.36600000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 606.29183,    # .{2}
    gross_price_orig => 8443000,      # .{3}
    net_price        => 608.11070549, # .{4}
    net_price_orig   => 8468329,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [154]
  {
    base_size        => "0.09461072", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 606.7945,     # .{2}
    gross_price_orig => 8450000,      # .{3}
    net_price        => 608.6148835,  # .{4}
    net_price_orig   => 8475350,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [155]
  {
    base_size        => "0.02200000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 607.44079,    # .{2}
    gross_price_orig => 8459000,      # .{3}
    net_price        => 609.26311237, # .{4}
    net_price_orig   => 8484377,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [156]
  {
    base_size        => "0.05735495", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 608.2307,     # .{2}
    gross_price_orig => 8470000,      # .{3}
    net_price        => 610.0553921,  # .{4}
    net_price_orig   => 8495410,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [157]
  {
    base_size        => "1.27598397", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 609.09242,    # .{2}
    gross_price_orig => 8482000,      # .{3}
    net_price        => 610.91969726, # .{4}
    net_price_orig   => 8507446,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [158]
  {
    base_size        => "0.05000061", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 609.6669,     # .{2}
    gross_price_orig => 8490000,      # .{3}
    net_price        => 611.4959007,  # .{4}
    net_price_orig   => 8515470,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [159]
  {
    base_size        => "99.47871620", # .{0}
    exchange         => "indodax",     # .{1}
    gross_price      => 610.385,       # .{2}
    gross_price_orig => 8500000,       # .{3}
    net_price        => 612.216155,    # .{4}
    net_price_orig   => 8525500,       # .{5}
    quote_currency   => "IDR",         # .{6}
  }, # [160]
  {
    base_size        => "8.87704703", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 610.45681,    # .{2}
    gross_price_orig => 8501000,      # .{3}
    net_price        => 612.28818043, # .{4}
    net_price_orig   => 8526503,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [161]
  {
    base_size        => "0.09146072", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 610.74405,    # .{2}
    gross_price_orig => 8505000,      # .{3}
    net_price        => 612.57628215, # .{4}
    net_price_orig   => 8530515,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [162]
  {
    base_size        => "0.06067961", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 611.24672,    # .{2}
    gross_price_orig => 8512000,      # .{3}
    net_price        => 613.08046016, # .{4}
    net_price_orig   => 8537536,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [163]
  {
    base_size        => "2.69532461", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 611.67758,    # .{2}
    gross_price_orig => 8518000,      # .{3}
    net_price        => 613.51261274, # .{4}
    net_price_orig   => 8543554,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [164]
  {
    base_size        => "0.15010640", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 612.03663,    # .{2}
    gross_price_orig => 8523000,      # .{3}
    net_price        => 613.87273989, # .{4}
    net_price_orig   => 8548569,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [165]
  {
    base_size        => "1.11561002", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 612.18025,    # .{2}
    gross_price_orig => 8525000,      # .{3}
    net_price        => 614.01679075, # .{4}
    net_price_orig   => 8550575,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [166]
  {
    base_size        => "1.51059787", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 612.5393,     # .{2}
    gross_price_orig => 8530000,      # .{3}
    net_price        => 614.3769179,  # .{4}
    net_price_orig   => 8555590,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [167]
  {
    base_size        => "0.30613855", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 612.61111,    # .{2}
    gross_price_orig => 8531000,      # .{3}
    net_price        => 614.44894333, # .{4}
    net_price_orig   => 8556593,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [168]
  {
    base_size        => "0.07769444", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 613.54464,    # .{2}
    gross_price_orig => 8544000,      # .{3}
    net_price        => 615.38527392, # .{4}
    net_price_orig   => 8569632,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [169]
  {
    base_size        => "2.00010823", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 613.76007,    # .{2}
    gross_price_orig => 8547000,      # .{3}
    net_price        => 615.60135021, # .{4}
    net_price_orig   => 8572641,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [170]
  {
    base_size        => "3.14377106", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 613.9755,     # .{2}
    gross_price_orig => 8550000,      # .{3}
    net_price        => 615.8174265,  # .{4}
    net_price_orig   => 8575650,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [171]
  {
    base_size        => "0.01866434", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 614.26274,    # .{2}
    gross_price_orig => 8554000,      # .{3}
    net_price        => 616.10552822, # .{4}
    net_price_orig   => 8579662,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [172]
  {
    base_size        => "1.02670413", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 614.33455,    # .{2}
    gross_price_orig => 8555000,      # .{3}
    net_price        => 616.17755365, # .{4}
    net_price_orig   => 8580665,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [173]
  {
    base_size        => "2.03417811", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 614.62179,    # .{2}
    gross_price_orig => 8559000,      # .{3}
    net_price        => 616.46565537, # .{4}
    net_price_orig   => 8584677,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [174]
  {
    base_size        => "0.11265981", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 615.12446,    # .{2}
    gross_price_orig => 8566000,      # .{3}
    net_price        => 616.96983338, # .{4}
    net_price_orig   => 8591698,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [175]
  {
    base_size        => "1.00000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 615.77075,    # .{2}
    gross_price_orig => 8575000,      # .{3}
    net_price        => 617.61806225, # .{4}
    net_price_orig   => 8600725,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [176]
  {
    base_size        => "1.19177805", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 616.1298,     # .{2}
    gross_price_orig => 8580000,      # .{3}
    net_price        => 617.9781894,  # .{4}
    net_price_orig   => 8605740,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [177]
  {
    base_size        => "0.05461111", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 616.63247,    # .{2}
    gross_price_orig => 8587000,      # .{3}
    net_price        => 618.48236741, # .{4}
    net_price_orig   => 8612761,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [178]
  {
    base_size        => "0.09847614", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 616.77609,    # .{2}
    gross_price_orig => 8589000,      # .{3}
    net_price        => 618.62641827, # .{4}
    net_price_orig   => 8614767,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [179]
  {
    base_size        => "0.09044039", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 616.91971,    # .{2}
    gross_price_orig => 8591000,      # .{3}
    net_price        => 618.77046913, # .{4}
    net_price_orig   => 8616773,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [180]
  {
    base_size        => "0.02070983", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 617.35057,    # .{2}
    gross_price_orig => 8597000,      # .{3}
    net_price        => 619.20262171, # .{4}
    net_price_orig   => 8622791,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [181]
  {
    base_size        => "0.23275373", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 617.49419,    # .{2}
    gross_price_orig => 8599000,      # .{3}
    net_price        => 619.34667257, # .{4}
    net_price_orig   => 8624797,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [182]
  {
    base_size        => "5.59412406", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 617.566,      # .{2}
    gross_price_orig => 8600000,      # .{3}
    net_price        => 619.418698,   # .{4}
    net_price_orig   => 8625800,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [183]
  {
    base_size        => "0.93205224", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 617.85324,    # .{2}
    gross_price_orig => 8604000,      # .{3}
    net_price        => 619.70679972, # .{4}
    net_price_orig   => 8629812,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [184]
  {
    base_size        => "2.77768505", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 617.99686,    # .{2}
    gross_price_orig => 8606000,      # .{3}
    net_price        => 619.85085058, # .{4}
    net_price_orig   => 8631818,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [185]
  {
    base_size        => "0.13985379", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 618.21229,    # .{2}
    gross_price_orig => 8609000,      # .{3}
    net_price        => 620.06692687, # .{4}
    net_price_orig   => 8634827,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [186]
  {
    base_size        => "0.02950353", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 618.2841,     # .{2}
    gross_price_orig => 8610000,      # .{3}
    net_price        => 620.1389523,  # .{4}
    net_price_orig   => 8635830,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [187]
  {
    base_size        => "0.02358907", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 618.57134,    # .{2}
    gross_price_orig => 8614000,      # .{3}
    net_price        => 620.42705402, # .{4}
    net_price_orig   => 8639842,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [188]
  {
    base_size        => "1.85185185", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 618.64315,    # .{2}
    gross_price_orig => 8615000,      # .{3}
    net_price        => 620.49907945, # .{4}
    net_price_orig   => 8640845,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [189]
  {
    base_size        => "0.05000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 619.36125,    # .{2}
    gross_price_orig => 8625000,      # .{3}
    net_price        => 621.21933375, # .{4}
    net_price_orig   => 8650875,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [190]
  {
    base_size        => "0.50000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 619.7203,     # .{2}
    gross_price_orig => 8630000,      # .{3}
    net_price        => 621.5794609,  # .{4}
    net_price_orig   => 8655890,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [191]
  {
    base_size        => "0.05025188", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 620.58202,    # .{2}
    gross_price_orig => 8642000,      # .{3}
    net_price        => 622.44376606, # .{4}
    net_price_orig   => 8667926,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [192]
  {
    base_size        => "2.41480176", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 621.1565,     # .{2}
    gross_price_orig => 8650000,      # .{3}
    net_price        => 623.0199695,  # .{4}
    net_price_orig   => 8675950,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [193]
  {
    base_size        => "0.01800000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 621.65917,    # .{2}
    gross_price_orig => 8657000,      # .{3}
    net_price        => 623.52414751, # .{4}
    net_price_orig   => 8682971,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [194]
  {
    base_size        => "0.15077888", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 622.01822,    # .{2}
    gross_price_orig => 8662000,      # .{3}
    net_price        => 623.88427466, # .{4}
    net_price_orig   => 8687986,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [195]
  {
    base_size        => "0.01000000", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 622.16184,    # .{2}
    gross_price_orig => 8664000,      # .{3}
    net_price        => 624.02832552, # .{4}
    net_price_orig   => 8689992,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [196]
  {
    base_size        => "0.51199673", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 622.30546,    # .{2}
    gross_price_orig => 8666000,      # .{3}
    net_price        => 624.17237638, # .{4}
    net_price_orig   => 8691998,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [197]
  {
    base_size        => "0.07746830", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 622.37727,    # .{2}
    gross_price_orig => 8667000,      # .{3}
    net_price        => 624.24440181, # .{4}
    net_price_orig   => 8693001,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [198]
  {
    base_size        => "0.20253125", # .{0}
    exchange         => "indodax",    # .{1}
    gross_price      => 622.95175,    # .{2}
    gross_price_orig => 8675000,      # .{3}
    net_price        => 624.82060525, # .{4}
    net_price_orig   => 8701025,      # .{5}
    quote_currency   => "IDR",        # .{6}
  }, # [199]
];

    my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
        base_currency  => "ETH",
        all_buy_orders    => $all_buy_orders,
        all_sell_orders   => $all_sell_orders,
        min_profit_pct    => 3.0,
    );

    ok 1;
};

DONE_TESTING:
done_testing;
