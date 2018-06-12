#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use App::cryp::arbit::Strategy::merge_order_book;

my $all_buy_orders0 = [
  {
    amount           => "0.02333052",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => "107314000",   # .{3}
    gross_price_usd  => 7723.38858,    # .{4}
    net_price_orig   => 106992058,     # .{5}
    net_price_usd    => 7700.21841426, # .{6}
  }, # [  0]
  {
    amount           => "0.00931854",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107313000,     # .{3}
    gross_price_usd  => 7723.31661,    # .{4}
    net_price_orig   => 106991061,     # .{5}
    net_price_usd    => 7700.14666017, # .{6}
  }, # [  1]
  {
    amount           => "0.00637147",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107312000,     # .{3}
    gross_price_usd  => 7723.24464,    # .{4}
    net_price_orig   => 106990064,     # .{5}
    net_price_usd    => 7700.07490608, # .{6}
  }, # [  2]
  {
    amount           => "0.79269091", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107310000,    # .{3}
    gross_price_usd  => 7723.1007,    # .{4}
    net_price_orig   => 106988070,    # .{5}
    net_price_usd    => 7699.9313979, # .{6}
  }, # [  3]
  {
    amount           => "0.00100689",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107307000,     # .{3}
    gross_price_usd  => 7722.88479,    # .{4}
    net_price_orig   => 106985079,     # .{5}
    net_price_usd    => 7699.71613563, # .{6}
  }, # [  4]
  {
    amount           => "0.00280404",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107305000,     # .{3}
    gross_price_usd  => 7722.74085,    # .{4}
    net_price_orig   => 106983085,     # .{5}
    net_price_usd    => 7699.57262745, # .{6}
  }, # [  5]
  {
    amount           => "0.00512577",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107301000,     # .{3}
    gross_price_usd  => 7722.45297,    # .{4}
    net_price_orig   => 106979097,     # .{5}
    net_price_usd    => 7699.28561109, # .{6}
  }, # [  6]
  {
    amount           => "0.00264583", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107300000,    # .{3}
    gross_price_usd  => 7722.381,     # .{4}
    net_price_orig   => 106978100,    # .{5}
    net_price_usd    => 7699.213857,  # .{6}
  }, # [  7]
  {
    amount           => "0.06056389",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107257000,     # .{3}
    gross_price_usd  => 7719.28629,    # .{4}
    net_price_orig   => 106935229,     # .{5}
    net_price_usd    => 7696.12843113, # .{6}
  }, # [  8]
  {
    amount           => "0.08087590",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107256000,     # .{3}
    gross_price_usd  => 7719.21432,    # .{4}
    net_price_orig   => 106934232,     # .{5}
    net_price_usd    => 7696.05667704, # .{6}
  }, # [  9]
  {
    amount           => "0.11561772", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107250000,    # .{3}
    gross_price_usd  => 7718.7825,    # .{4}
    net_price_orig   => 106928250,    # .{5}
    net_price_usd    => 7695.6261525, # .{6}
  }, # [ 10]
  {
    amount           => "0.00560340", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107200000,    # .{3}
    gross_price_usd  => 7715.184,     # .{4}
    net_price_orig   => 106878400,    # .{5}
    net_price_usd    => 7692.038448,  # .{6}
  }, # [ 11]
  {
    amount           => "0.00186576",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107195000,     # .{3}
    gross_price_usd  => 7714.82415,    # .{4}
    net_price_orig   => 106873415,     # .{5}
    net_price_usd    => 7691.67967755, # .{6}
  }, # [ 12]
  {
    amount           => "0.03744656",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107134000,     # .{3}
    gross_price_usd  => 7710.43398,    # .{4}
    net_price_orig   => 106812598,     # .{5}
    net_price_usd    => 7687.30267806, # .{6}
  }, # [ 13]
  {
    amount           => "1.69107344",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107133000,     # .{3}
    gross_price_usd  => 7710.36201,    # .{4}
    net_price_orig   => 106811601,     # .{5}
    net_price_usd    => 7687.23092397, # .{6}
  }, # [ 14]
  {
    amount           => "0.00093343",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107132000,     # .{3}
    gross_price_usd  => 7710.29004,    # .{4}
    net_price_orig   => 106810604,     # .{5}
    net_price_usd    => 7687.15916988, # .{6}
  }, # [ 15]
  {
    amount           => "0.01121057",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107113000,     # .{3}
    gross_price_usd  => 7708.92261,    # .{4}
    net_price_orig   => 106791661,     # .{5}
    net_price_usd    => 7685.79584217, # .{6}
  }, # [ 16]
  {
    amount           => "0.00090399",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107111000,     # .{3}
    gross_price_usd  => 7708.77867,    # .{4}
    net_price_orig   => 106789667,     # .{5}
    net_price_usd    => 7685.65233399, # .{6}
  }, # [ 17]
  {
    amount           => "0.00296953",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107106000,     # .{3}
    gross_price_usd  => 7708.41882,    # .{4}
    net_price_orig   => 106784682,     # .{5}
    net_price_usd    => 7685.29356354, # .{6}
  }, # [ 18]
  {
    amount           => "0.34521409",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107105000,     # .{3}
    gross_price_usd  => 7708.34685,    # .{4}
    net_price_orig   => 106783685,     # .{5}
    net_price_usd    => 7685.22180945, # .{6}
  }, # [ 19]
  {
    amount           => "0.02632051", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107100000,    # .{3}
    gross_price_usd  => 7707.987,     # .{4}
    net_price_orig   => 106778700,    # .{5}
    net_price_usd    => 7684.863039,  # .{6}
  }, # [ 20]
  {
    amount           => "0.01877817",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107075000,     # .{3}
    gross_price_usd  => 7706.18775,    # .{4}
    net_price_orig   => 106753775,     # .{5}
    net_price_usd    => 7683.06918675, # .{6}
  }, # [ 21]
  {
    amount           => "3.97815566", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107030000,    # .{3}
    gross_price_usd  => 7702.9491,    # .{4}
    net_price_orig   => 106708910,    # .{5}
    net_price_usd    => 7679.8402527, # .{6}
  }, # [ 22]
  {
    amount           => "0.00934326",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107029000,     # .{3}
    gross_price_usd  => 7702.87713,    # .{4}
    net_price_orig   => 106707913,     # .{5}
    net_price_usd    => 7679.76849861, # .{6}
  }, # [ 23]
  {
    amount           => "0.04672024", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107020000,    # .{3}
    gross_price_usd  => 7702.2294,    # .{4}
    net_price_orig   => 106698940,    # .{5}
    net_price_usd    => 7679.1227118, # .{6}
  }, # [ 24]
  {
    amount           => "0.00153235",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107002000,     # .{3}
    gross_price_usd  => 7700.93394,    # .{4}
    net_price_orig   => 106680994,     # .{5}
    net_price_usd    => 7677.83113818, # .{6}
  }, # [ 25]
  {
    amount           => "0.58895098", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107000000,    # .{3}
    gross_price_usd  => 7700.79,      # .{4}
    net_price_orig   => 106679000,    # .{5}
    net_price_usd    => 7677.68763,   # .{6}
  }, # [ 26]
  {
    amount           => "0.00093793",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106965000,     # .{3}
    gross_price_usd  => 7698.27105,    # .{4}
    net_price_orig   => 106644105,     # .{5}
    net_price_usd    => 7675.17623685, # .{6}
  }, # [ 27]
  {
    amount           => "0.00277715",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106959000,     # .{3}
    gross_price_usd  => 7697.83923,    # .{4}
    net_price_orig   => 106638123,     # .{5}
    net_price_usd    => 7674.74571231, # .{6}
  }, # [ 28]
  {
    amount           => "0.04005505",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106958000,     # .{3}
    gross_price_usd  => 7697.76726,    # .{4}
    net_price_orig   => 106637126,     # .{5}
    net_price_usd    => 7674.67395822, # .{6}
  }, # [ 29]
  {
    amount           => "0.21401324",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106956000,     # .{3}
    gross_price_usd  => 7697.62332,    # .{4}
    net_price_orig   => 106635132,     # .{5}
    net_price_usd    => 7674.53045004, # .{6}
  }, # [ 30]
  {
    amount           => "0.01399163",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106953000,     # .{3}
    gross_price_usd  => 7697.40741,    # .{4}
    net_price_orig   => 106632141,     # .{5}
    net_price_usd    => 7674.31518777, # .{6}
  }, # [ 31]
  {
    amount           => "0.00122042", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106920000,    # .{3}
    gross_price_usd  => 7695.0324,    # .{4}
    net_price_orig   => 106599240,    # .{5}
    net_price_usd    => 7671.9473028, # .{6}
  }, # [ 32]
  {
    amount           => "0.00467727", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106900000,    # .{3}
    gross_price_usd  => 7693.593,     # .{4}
    net_price_orig   => 106579300,    # .{5}
    net_price_usd    => 7670.512221,  # .{6}
  }, # [ 33]
  {
    amount           => "0.00046777",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106889000,     # .{3}
    gross_price_usd  => 7692.80133,    # .{4}
    net_price_orig   => 106568333,     # .{5}
    net_price_usd    => 7669.72292601, # .{6}
  }, # [ 34]
  {
    amount           => "0.03103537",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106888000,     # .{3}
    gross_price_usd  => 7692.72936,    # .{4}
    net_price_orig   => 106567336,     # .{5}
    net_price_usd    => 7669.65117192, # .{6}
  }, # [ 35]
  {
    amount           => "0.00219643",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106851000,     # .{3}
    gross_price_usd  => 7690.06647,    # .{4}
    net_price_orig   => 106530447,     # .{5}
    net_price_usd    => 7666.99627059, # .{6}
  }, # [ 36]
  {
    amount           => "0.00077498",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106816000,     # .{3}
    gross_price_usd  => 7687.54752,    # .{4}
    net_price_orig   => 106495552,     # .{5}
    net_price_usd    => 7664.48487744, # .{6}
  }, # [ 37]
  {
    amount           => "0.01168986",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106802000,     # .{3}
    gross_price_usd  => 7686.53994,    # .{4}
    net_price_orig   => 106481594,     # .{5}
    net_price_usd    => 7663.48032018, # .{6}
  }, # [ 38]
  {
    amount           => "0.19719101", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106800000,    # .{3}
    gross_price_usd  => 7686.396,     # .{4}
    net_price_orig   => 106479600,    # .{5}
    net_price_usd    => 7663.336812,  # .{6}
  }, # [ 39]
  {
    amount           => "0.01522053",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106799000,     # .{3}
    gross_price_usd  => 7686.32403,    # .{4}
    net_price_orig   => 106478603,     # .{5}
    net_price_usd    => 7663.26505791, # .{6}
  }, # [ 40]
  {
    amount           => "0.00096273",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106796000,     # .{3}
    gross_price_usd  => 7686.10812,    # .{4}
    net_price_orig   => 106475612,     # .{5}
    net_price_usd    => 7663.04979564, # .{6}
  }, # [ 41]
  {
    amount           => "0.00281030", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106750000,    # .{3}
    gross_price_usd  => 7682.7975,    # .{4}
    net_price_orig   => 106429750,    # .{5}
    net_price_usd    => 7659.7491075, # .{6}
  }, # [ 42]
  {
    amount           => "0.01187708",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106746000,     # .{3}
    gross_price_usd  => 7682.50962,    # .{4}
    net_price_orig   => 106425762,     # .{5}
    net_price_usd    => 7659.46209114, # .{6}
  }, # [ 43]
  {
    amount           => "0.00140555", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106720000,    # .{3}
    gross_price_usd  => 7680.6384,    # .{4}
    net_price_orig   => 106399840,    # .{5}
    net_price_usd    => 7657.5964848, # .{6}
  }, # [ 44]
  {
    amount           => "0.00937040",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106719000,     # .{3}
    gross_price_usd  => 7680.56643,    # .{4}
    net_price_orig   => 106398843,     # .{5}
    net_price_usd    => 7657.52473071, # .{6}
  }, # [ 45]
  {
    amount           => "0.00050925",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106716000,     # .{3}
    gross_price_usd  => 7680.35052,    # .{4}
    net_price_orig   => 106395852,     # .{5}
    net_price_usd    => 7657.30946844, # .{6}
  }, # [ 46]
  {
    amount           => "0.01694796", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106700000,    # .{3}
    gross_price_usd  => 7679.199,     # .{4}
    net_price_orig   => 106379900,    # .{5}
    net_price_usd    => 7656.161403,  # .{6}
  }, # [ 47]
  {
    amount           => "0.00086210",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106691000,     # .{3}
    gross_price_usd  => 7678.55127,    # .{4}
    net_price_orig   => 106370927,     # .{5}
    net_price_usd    => 7655.51561619, # .{6}
  }, # [ 48]
  {
    amount           => "0.01078192", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106660000,    # .{3}
    gross_price_usd  => 7676.3202,    # .{4}
    net_price_orig   => 106340020,    # .{5}
    net_price_usd    => 7653.2912394, # .{6}
  }, # [ 49]
  {
    amount           => "0.01078223",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106657000,     # .{3}
    gross_price_usd  => 7676.10429,    # .{4}
    net_price_orig   => 106337029,     # .{5}
    net_price_usd    => 7653.07597713, # .{6}
  }, # [ 50]
  {
    amount           => "0.01078263",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106653000,     # .{3}
    gross_price_usd  => 7675.81641,    # .{4}
    net_price_orig   => 106333041,     # .{5}
    net_price_usd    => 7652.78896077, # .{6}
  }, # [ 51]
  {
    amount           => "0.16295129", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106650000,    # .{3}
    gross_price_usd  => 7675.6005,    # .{4}
    net_price_orig   => 106330050,    # .{5}
    net_price_usd    => 7652.5736985, # .{6}
  }, # [ 52]
  {
    amount           => "0.00140654",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106645000,     # .{3}
    gross_price_usd  => 7675.24065,    # .{4}
    net_price_orig   => 106325065,     # .{5}
    net_price_usd    => 7652.21492805, # .{6}
  }, # [ 53]
  {
    amount           => "0.23487214",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106641000,     # .{3}
    gross_price_usd  => 7674.95277,    # .{4}
    net_price_orig   => 106321077,     # .{5}
    net_price_usd    => 7651.92791169, # .{6}
  }, # [ 54]
  {
    amount           => "0.98477814",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106623000,     # .{3}
    gross_price_usd  => 7673.65731,    # .{4}
    net_price_orig   => 106303131,     # .{5}
    net_price_usd    => 7650.63633807, # .{6}
  }, # [ 55]
  {
    amount           => "2.50002110",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106622000,     # .{3}
    gross_price_usd  => 7673.58534,    # .{4}
    net_price_orig   => 106302134,     # .{5}
    net_price_usd    => 7650.56458398, # .{6}
  }, # [ 56]
  {
    amount           => "0.03398512", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106600000,    # .{3}
    gross_price_usd  => 7672.002,     # .{4}
    net_price_orig   => 106280200,    # .{5}
    net_price_usd    => 7648.985994,  # .{6}
  }, # [ 57]
  {
    amount           => "0.00938104",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106598000,     # .{3}
    gross_price_usd  => 7671.85806,    # .{4}
    net_price_orig   => 106278206,     # .{5}
    net_price_usd    => 7648.84248582, # .{6}
  }, # [ 58]
  {
    amount           => "0.00179227",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106585000,     # .{3}
    gross_price_usd  => 7670.92245,    # .{4}
    net_price_orig   => 106265245,     # .{5}
    net_price_usd    => 7647.90968265, # .{6}
  }, # [ 59]
  {
    amount           => "0.00941980",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106584000,     # .{3}
    gross_price_usd  => 7670.85048,    # .{4}
    net_price_orig   => 106264248,     # .{5}
    net_price_usd    => 7647.83792856, # .{6}
  }, # [ 60]
  {
    amount           => "0.00944616",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106562000,     # .{3}
    gross_price_usd  => 7669.26714,    # .{4}
    net_price_orig   => 106242314,     # .{5}
    net_price_usd    => 7646.25933858, # .{6}
  }, # [ 61]
  {
    amount           => "0.01702410", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106550000,    # .{3}
    gross_price_usd  => 7668.4035,    # .{4}
    net_price_orig   => 106230350,    # .{5}
    net_price_usd    => 7645.3982895, # .{6}
  }, # [ 62]
  {
    amount           => "0.00841576",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106548000,     # .{3}
    gross_price_usd  => 7668.25956,    # .{4}
    net_price_orig   => 106228356,     # .{5}
    net_price_usd    => 7645.25478132, # .{6}
  }, # [ 63]
  {
    amount           => "0.17500000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106529000,     # .{3}
    gross_price_usd  => 7666.89213,    # .{4}
    net_price_orig   => 106209413,     # .{5}
    net_price_usd    => 7643.89145361, # .{6}
  }, # [ 64]
  {
    amount           => "0.14080805",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106528000,     # .{3}
    gross_price_usd  => 7666.82016,    # .{4}
    net_price_orig   => 106208416,     # .{5}
    net_price_usd    => 7643.81969952, # .{6}
  }, # [ 65]
  {
    amount           => "0.00938914",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106506000,     # .{3}
    gross_price_usd  => 7665.23682,    # .{4}
    net_price_orig   => 106186482,     # .{5}
    net_price_usd    => 7642.24110954, # .{6}
  }, # [ 66]
  {
    amount           => "0.00938923",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106505000,     # .{3}
    gross_price_usd  => 7665.16485,    # .{4}
    net_price_orig   => 106185485,     # .{5}
    net_price_usd    => 7642.16935545, # .{6}
  }, # [ 67]
  {
    amount           => "0.00938950",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106502000,     # .{3}
    gross_price_usd  => 7664.94894,    # .{4}
    net_price_orig   => 106182494,     # .{5}
    net_price_usd    => 7641.95409318, # .{6}
  }, # [ 68]
  {
    amount           => "0.02477354",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106501000,     # .{3}
    gross_price_usd  => 7664.87697,    # .{4}
    net_price_orig   => 106181497,     # .{5}
    net_price_usd    => 7641.88233909, # .{6}
  }, # [ 69]
  {
    amount           => "0.58700345", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106500000,    # .{3}
    gross_price_usd  => 7664.805,     # .{4}
    net_price_orig   => 106180500,    # .{5}
    net_price_usd    => 7641.810585,  # .{6}
  }, # [ 70]
  {
    amount           => "0.04694968",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106497000,     # .{3}
    gross_price_usd  => 7664.58909,    # .{4}
    net_price_orig   => 106177509,     # .{5}
    net_price_usd    => 7641.59532273, # .{6}
  }, # [ 71]
  {
    amount           => "0.02715287",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106489000,     # .{3}
    gross_price_usd  => 7664.01333,    # .{4}
    net_price_orig   => 106169533,     # .{5}
    net_price_usd    => 7641.02129001, # .{6}
  }, # [ 72]
  {
    amount           => "0.00093036",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106478000,     # .{3}
    gross_price_usd  => 7663.22166,    # .{4}
    net_price_orig   => 106158566,     # .{5}
    net_price_usd    => 7640.23199502, # .{6}
  }, # [ 73]
  {
    amount           => "0.05066778",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106458000,     # .{3}
    gross_price_usd  => 7661.78226,    # .{4}
    net_price_orig   => 106138626,     # .{5}
    net_price_usd    => 7638.79691322, # .{6}
  }, # [ 74]
  {
    amount           => "0.01878693",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106457000,     # .{3}
    gross_price_usd  => 7661.71029,    # .{4}
    net_price_orig   => 106137629,     # .{5}
    net_price_usd    => 7638.72515913, # .{6}
  }, # [ 75]
  {
    amount           => "0.00196000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106432000,     # .{3}
    gross_price_usd  => 7659.91104,    # .{4}
    net_price_orig   => 106112704,     # .{5}
    net_price_usd    => 7636.93130688, # .{6}
  }, # [ 76]
  {
    amount           => "0.00093964",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106424000,     # .{3}
    gross_price_usd  => 7659.33528,    # .{4}
    net_price_orig   => 106104728,     # .{5}
    net_price_usd    => 7636.35727416, # .{6}
  }, # [ 77]
  {
    amount           => "0.00091632", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106400000,    # .{3}
    gross_price_usd  => 7657.608,     # .{4}
    net_price_orig   => 106080800,    # .{5}
    net_price_usd    => 7634.635176,  # .{6}
  }, # [ 78]
  {
    amount           => "0.00098788",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106396000,     # .{3}
    gross_price_usd  => 7657.32012,    # .{4}
    net_price_orig   => 106076812,     # .{5}
    net_price_usd    => 7634.34815964, # .{6}
  }, # [ 79]
  {
    amount           => "0.18100000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106334000,     # .{3}
    gross_price_usd  => 7652.85798,    # .{4}
    net_price_orig   => 106014998,     # .{5}
    net_price_usd    => 7629.89940606, # .{6}
  }, # [ 80]
  {
    amount           => "0.03119737",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106333000,     # .{3}
    gross_price_usd  => 7652.78601,    # .{4}
    net_price_orig   => 106014001,     # .{5}
    net_price_usd    => 7629.82765197, # .{6}
  }, # [ 81]
  {
    amount           => "0.00058733",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106325000,     # .{3}
    gross_price_usd  => 7652.21025,    # .{4}
    net_price_orig   => 106006025,     # .{5}
    net_price_usd    => 7629.25361925, # .{6}
  }, # [ 82]
  {
    amount           => "0.04859322", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106320000,    # .{3}
    gross_price_usd  => 7651.8504,    # .{4}
    net_price_orig   => 106001040,    # .{5}
    net_price_usd    => 7628.8948488, # .{6}
  }, # [ 83]
  {
    amount           => "0.00940645", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106310000,    # .{3}
    gross_price_usd  => 7651.1307,    # .{4}
    net_price_orig   => 105991070,    # .{5}
    net_price_usd    => 7628.1773079, # .{6}
  }, # [ 84]
  {
    amount           => "0.00940725",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106301000,     # .{3}
    gross_price_usd  => 7650.48297,    # .{4}
    net_price_orig   => 105982097,     # .{5}
    net_price_usd    => 7627.53152109, # .{6}
  }, # [ 85]
  {
    amount           => "0.00058404", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106300000,    # .{3}
    gross_price_usd  => 7650.411,     # .{4}
    net_price_orig   => 105981100,    # .{5}
    net_price_usd    => 7627.459767,  # .{6}
  }, # [ 86]
  {
    amount           => "0.00282233",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106295000,     # .{3}
    gross_price_usd  => 7650.05115,    # .{4}
    net_price_orig   => 105976115,     # .{5}
    net_price_usd    => 7627.10099655, # .{6}
  }, # [ 87]
  {
    amount           => "0.00627525",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106294000,     # .{3}
    gross_price_usd  => 7649.97918,    # .{4}
    net_price_orig   => 105975118,     # .{5}
    net_price_usd    => 7627.02924246, # .{6}
  }, # [ 88]
  {
    amount           => "0.00098392", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106250000,    # .{3}
    gross_price_usd  => 7646.8125,    # .{4}
    net_price_orig   => 105931250,    # .{5}
    net_price_usd    => 7623.8720625, # .{6}
  }, # [ 89]
  {
    amount           => "0.02890000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106235000,     # .{3}
    gross_price_usd  => 7645.73295,    # .{4}
    net_price_orig   => 105916295,     # .{5}
    net_price_usd    => 7622.79575115, # .{6}
  }, # [ 90]
  {
    amount           => "0.00141272",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106219000,     # .{3}
    gross_price_usd  => 7644.58143,    # .{4}
    net_price_orig   => 105900343,     # .{5}
    net_price_usd    => 7621.64768571, # .{6}
  }, # [ 91]
  {
    amount           => "0.00396584",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106205000,     # .{3}
    gross_price_usd  => 7643.57385,    # .{4}
    net_price_orig   => 105886385,     # .{5}
    net_price_usd    => 7620.64312845, # .{6}
  }, # [ 92]
  {
    amount           => "0.00941593",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106203000,     # .{3}
    gross_price_usd  => 7643.42991,    # .{4}
    net_price_orig   => 105884391,     # .{5}
    net_price_usd    => 7620.49962027, # .{6}
  }, # [ 93]
  {
    amount           => "24.20011393", # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106201000,     # .{3}
    gross_price_usd  => 7643.28597,    # .{4}
    net_price_orig   => 105882397,     # .{5}
    net_price_usd    => 7620.35611209, # .{6}
  }, # [ 94]
  {
    amount           => "1.97771330", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106200000,    # .{3}
    gross_price_usd  => 7643.214,     # .{4}
    net_price_orig   => 105881400,    # .{5}
    net_price_usd    => 7620.284358,  # .{6}
  }, # [ 95]
  {
    amount           => "0.00052442", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106190000,    # .{3}
    gross_price_usd  => 7642.4943,    # .{4}
    net_price_orig   => 105871430,    # .{5}
    net_price_usd    => 7619.5668171, # .{6}
  }, # [ 96]
  {
    amount           => "0.00216543",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106148000,     # .{3}
    gross_price_usd  => 7639.47156,    # .{4}
    net_price_orig   => 105829556,     # .{5}
    net_price_usd    => 7616.55314532, # .{6}
  }, # [ 97]
  {
    amount           => "0.00942223",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106132000,     # .{3}
    gross_price_usd  => 7638.32004,    # .{4}
    net_price_orig   => 105813604,     # .{5}
    net_price_usd    => 7615.40507988, # .{6}
  }, # [ 98]
  {
    amount           => "0.00187862",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106123000,     # .{3}
    gross_price_usd  => 7637.67231,    # .{4}
    net_price_orig   => 105804631,     # .{5}
    net_price_usd    => 7614.75929307, # .{6}
  }, # [ 99]
  {
    amount           => "0.00441483",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106111000,     # .{3}
    gross_price_usd  => 7636.80867,    # .{4}
    net_price_orig   => 105792667,     # .{5}
    net_price_usd    => 7613.89824399, # .{6}
  }, # [100]
  {
    amount           => "0.47119254",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106101000,     # .{3}
    gross_price_usd  => 7636.08897,    # .{4}
    net_price_orig   => 105782697,     # .{5}
    net_price_usd    => 7613.18070309, # .{6}
  }, # [101]
  {
    amount           => "2.20062115", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106100000,    # .{3}
    gross_price_usd  => 7636.017,     # .{4}
    net_price_orig   => 105781700,    # .{5}
    net_price_usd    => 7613.108949,  # .{6}
  }, # [102]
  {
    amount           => "0.26273695",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106092000,     # .{3}
    gross_price_usd  => 7635.44124,    # .{4}
    net_price_orig   => 105773724,     # .{5}
    net_price_usd    => 7612.53491628, # .{6}
  }, # [103]
  {
    amount           => "0.00942845",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106062000,     # .{3}
    gross_price_usd  => 7633.28214,    # .{4}
    net_price_orig   => 105743814,     # .{5}
    net_price_usd    => 7610.38229358, # .{6}
  }, # [104]
  {
    amount           => "0.00942863", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106060000,    # .{3}
    gross_price_usd  => 7633.1382,    # .{4}
    net_price_orig   => 105741820,    # .{5}
    net_price_usd    => 7610.2387854, # .{6}
  }, # [105]
  {
    amount           => "0.00942889",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106057000,     # .{3}
    gross_price_usd  => 7632.92229,    # .{4}
    net_price_orig   => 105738829,     # .{5}
    net_price_usd    => 7610.02352313, # .{6}
  }, # [106]
  {
    amount           => "0.00047157",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106029000,     # .{3}
    gross_price_usd  => 7630.90713,    # .{4}
    net_price_orig   => 105710913,     # .{5}
    net_price_usd    => 7608.01440861, # .{6}
  }, # [107]
  {
    amount           => "0.00943183",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106024000,     # .{3}
    gross_price_usd  => 7630.54728,    # .{4}
    net_price_orig   => 105705928,     # .{5}
    net_price_usd    => 7607.65563816, # .{6}
  }, # [108]
  {
    amount           => "0.00943218", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106020000,    # .{3}
    gross_price_usd  => 7630.2594,    # .{4}
    net_price_orig   => 105701940,    # .{5}
    net_price_usd    => 7607.3686218, # .{6}
  }, # [109]
  {
    amount           => "0.00943307", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106010000,    # .{3}
    gross_price_usd  => 7629.5397,    # .{4}
    net_price_orig   => 105691970,    # .{5}
    net_price_usd    => 7606.6510809, # .{6}
  }, # [110]
  {
    amount           => "0.01217513",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106008000,     # .{3}
    gross_price_usd  => 7629.39576,    # .{4}
    net_price_orig   => 105689976,     # .{5}
    net_price_usd    => 7606.50757272, # .{6}
  }, # [111]
  {
    amount           => "0.12343439",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106006000,     # .{3}
    gross_price_usd  => 7629.25182,    # .{4}
    net_price_orig   => 105687982,     # .{5}
    net_price_usd    => 7606.36406454, # .{6}
  }, # [112]
  {
    amount           => "0.00423008",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106004000,     # .{3}
    gross_price_usd  => 7629.10788,    # .{4}
    net_price_orig   => 105685988,     # .{5}
    net_price_usd    => 7606.22055636, # .{6}
  }, # [113]
  {
    amount           => "0.00047168",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 106003000,     # .{3}
    gross_price_usd  => 7629.03591,    # .{4}
    net_price_orig   => 105684991,     # .{5}
    net_price_usd    => 7606.14880227, # .{6}
  }, # [114]
  {
    amount           => "3.08052274", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 106000000,    # .{3}
    gross_price_usd  => 7628.82,      # .{4}
    net_price_orig   => 105682000,    # .{5}
    net_price_usd    => 7605.93354,   # .{6}
  }, # [115]
  {
    amount           => "0.18868459",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105997000,     # .{3}
    gross_price_usd  => 7628.60409,    # .{4}
    net_price_orig   => 105679009,     # .{5}
    net_price_usd    => 7605.71827773, # .{6}
  }, # [116]
  {
    amount           => "0.47201578", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105930000,    # .{3}
    gross_price_usd  => 7623.7821,    # .{4}
    net_price_orig   => 105612210,    # .{5}
    net_price_usd    => 7600.9107537, # .{6}
  }, # [117]
  {
    amount           => "1.31637447", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105900000,    # .{3}
    gross_price_usd  => 7621.623,     # .{4}
    net_price_orig   => 105582300,    # .{5}
    net_price_usd    => 7598.758131,  # .{6}
  }, # [118]
  {
    amount           => "0.01974390",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105898000,     # .{3}
    gross_price_usd  => 7621.47906,    # .{4}
    net_price_orig   => 105580306,     # .{5}
    net_price_usd    => 7598.61462282, # .{6}
  }, # [119]
  {
    amount           => "0.02360985",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105888000,     # .{3}
    gross_price_usd  => 7620.75936,    # .{4}
    net_price_orig   => 105570336,     # .{5}
    net_price_usd    => 7597.89708192, # .{6}
  }, # [120]
  {
    amount           => "0.01359235",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105885000,     # .{3}
    gross_price_usd  => 7620.54345,    # .{4}
    net_price_orig   => 105567345,     # .{5}
    net_price_usd    => 7597.68181965, # .{6}
  }, # [121]
  {
    amount           => "0.00453811", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105860000,    # .{3}
    gross_price_usd  => 7618.7442,    # .{4}
    net_price_orig   => 105542420,    # .{5}
    net_price_usd    => 7595.8879674, # .{6}
  }, # [122]
  {
    amount           => "0.01624548", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105850000,    # .{3}
    gross_price_usd  => 7618.0245,    # .{4}
    net_price_orig   => 105532450,    # .{5}
    net_price_usd    => 7595.1704265, # .{6}
  }, # [123]
  {
    amount           => "0.00090108",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105846000,     # .{3}
    gross_price_usd  => 7617.73662,    # .{4}
    net_price_orig   => 105528462,     # .{5}
    net_price_usd    => 7594.88341014, # .{6}
  }, # [124]
  {
    amount           => "0.05270599",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105828000,     # .{3}
    gross_price_usd  => 7616.44116,    # .{4}
    net_price_orig   => 105510516,     # .{5}
    net_price_usd    => 7593.59183652, # .{6}
  }, # [125]
  {
    amount           => "0.07226756",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105812000,     # .{3}
    gross_price_usd  => 7615.28964,    # .{4}
    net_price_orig   => 105494564,     # .{5}
    net_price_usd    => 7592.44377108, # .{6}
  }, # [126]
  {
    amount           => "0.00393142",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105811000,     # .{3}
    gross_price_usd  => 7615.21767,    # .{4}
    net_price_orig   => 105493567,     # .{5}
    net_price_usd    => 7592.37201699, # .{6}
  }, # [127]
  {
    amount           => "0.00684151", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105810000,    # .{3}
    gross_price_usd  => 7615.1457,    # .{4}
    net_price_orig   => 105492570,    # .{5}
    net_price_usd    => 7592.3002629, # .{6}
  }, # [128]
  {
    amount           => "0.02074746",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105808000,     # .{3}
    gross_price_usd  => 7615.00176,    # .{4}
    net_price_orig   => 105490576,     # .{5}
    net_price_usd    => 7592.15675472, # .{6}
  }, # [129]
  {
    amount           => "0.09851229",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105803000,     # .{3}
    gross_price_usd  => 7614.64191,    # .{4}
    net_price_orig   => 105485591,     # .{5}
    net_price_usd    => 7591.79798427, # .{6}
  }, # [130]
  {
    amount           => "0.00048106",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105802000,     # .{3}
    gross_price_usd  => 7614.56994,    # .{4}
    net_price_orig   => 105484594,     # .{5}
    net_price_usd    => 7591.72623018, # .{6}
  }, # [131]
  {
    amount           => "0.00070390",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105801000,     # .{3}
    gross_price_usd  => 7614.49797,    # .{4}
    net_price_orig   => 105483597,     # .{5}
    net_price_usd    => 7591.65447609, # .{6}
  }, # [132]
  {
    amount           => "0.37879444", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105800000,    # .{3}
    gross_price_usd  => 7614.426,     # .{4}
    net_price_orig   => 105482600,    # .{5}
    net_price_usd    => 7591.582722,  # .{6}
  }, # [133]
  {
    amount           => "0.00047525",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105764000,     # .{3}
    gross_price_usd  => 7611.83508,    # .{4}
    net_price_orig   => 105446708,     # .{5}
    net_price_usd    => 7588.99957476, # .{6}
  }, # [134]
  {
    amount           => "0.00372135", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105750000,    # .{3}
    gross_price_usd  => 7610.8275,    # .{4}
    net_price_orig   => 105432750,    # .{5}
    net_price_usd    => 7587.9950175, # .{6}
  }, # [135]
  {
    amount           => "0.00058141",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105742000,     # .{3}
    gross_price_usd  => 7610.25174,    # .{4}
    net_price_orig   => 105424774,     # .{5}
    net_price_usd    => 7587.42098478, # .{6}
  }, # [136]
  {
    amount           => "0.00065040",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105727000,     # .{3}
    gross_price_usd  => 7609.17219,    # .{4}
    net_price_orig   => 105409819,     # .{5}
    net_price_usd    => 7586.34467343, # .{6}
  }, # [137]
  {
    amount           => "0.00096987",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105715000,     # .{3}
    gross_price_usd  => 7608.30855,    # .{4}
    net_price_orig   => 105397855,     # .{5}
    net_price_usd    => 7585.48362435, # .{6}
  }, # [138]
  {
    amount           => "0.00068834",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105713000,     # .{3}
    gross_price_usd  => 7608.16461,    # .{4}
    net_price_orig   => 105395861,     # .{5}
    net_price_usd    => 7585.34011617, # .{6}
  }, # [139]
  {
    amount           => "0.11655512", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105700000,    # .{3}
    gross_price_usd  => 7607.229,     # .{4}
    net_price_orig   => 105382900,    # .{5}
    net_price_usd    => 7584.407313,  # .{6}
  }, # [140]
  {
    amount           => "0.02365856", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105670000,    # .{3}
    gross_price_usd  => 7605.0699,    # .{4}
    net_price_orig   => 105352990,    # .{5}
    net_price_usd    => 7582.2546903, # .{6}
  }, # [141]
  {
    amount           => "4.01600516", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7600.99",    # .{3}
    gross_price_usd  => "7600.99",    # .{4}
    net_price_orig   => 7581.987525,  # .{5}
    net_price_usd    => 7581.987525,  # .{6}
  }, # [142]
  {
    amount           => "0.0025826", # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7600.98",   # .{3}
    gross_price_usd  => "7600.98",   # .{4}
    net_price_orig   => 7581.97755,  # .{5}
    net_price_usd    => 7581.97755,  # .{6}
  }, # [143]
  {
    amount           => "0.02692146",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105657000,     # .{3}
    gross_price_usd  => 7604.13429,    # .{4}
    net_price_orig   => 105340029,     # .{5}
    net_price_usd    => 7581.32188713, # .{6}
  }, # [144]
  {
    amount           => "0.3142",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7600.01",   # .{3}
    gross_price_usd  => "7600.01",   # .{4}
    net_price_orig   => 7581.009975, # .{5}
    net_price_usd    => 7581.009975, # .{6}
  }, # [145]
  {
    amount           => "4.88835667", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7600",       # .{3}
    gross_price_usd  => "7600",       # .{4}
    net_price_orig   => 7581,         # .{5}
    net_price_usd    => 7581,         # .{6}
  }, # [146]
  {
    amount           => "0.00232048",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105652000,     # .{3}
    gross_price_usd  => 7603.77444,    # .{4}
    net_price_orig   => 105335044,     # .{5}
    net_price_usd    => 7580.96311668, # .{6}
  }, # [147]
  {
    amount           => "9.4",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7599.67",   # .{3}
    gross_price_usd  => "7599.67",   # .{4}
    net_price_orig   => 7580.670825, # .{5}
    net_price_usd    => 7580.670825, # .{6}
  }, # [148]
  {
    amount           => "0.04855021",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105646000,     # .{3}
    gross_price_usd  => 7603.34262,    # .{4}
    net_price_orig   => 105329062,     # .{5}
    net_price_usd    => 7580.53259214, # .{6}
  }, # [149]
  {
    amount           => "0.2",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7598.93",   # .{3}
    gross_price_usd  => "7598.93",   # .{4}
    net_price_orig   => 7579.932675, # .{5}
    net_price_usd    => 7579.932675, # .{6}
  }, # [150]
  {
    amount           => "0.0024",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7598.77",   # .{3}
    gross_price_usd  => "7598.77",   # .{4}
    net_price_orig   => 7579.773075, # .{5}
    net_price_usd    => 7579.773075, # .{6}
  }, # [151]
  {
    amount           => "1",       # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7598.6",  # .{3}
    gross_price_usd  => "7598.6",  # .{4}
    net_price_orig   => 7579.6035, # .{5}
    net_price_usd    => 7579.6035, # .{6}
  }, # [152]
  {
    amount           => "0.25",      # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7598.01",   # .{3}
    gross_price_usd  => "7598.01",   # .{4}
    net_price_orig   => 7579.014975, # .{5}
    net_price_usd    => 7579.014975, # .{6}
  }, # [153]
  {
    amount           => "0.05",      # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7597.99",   # .{3}
    gross_price_usd  => "7597.99",   # .{4}
    net_price_orig   => 7578.995025, # .{5}
    net_price_usd    => 7578.995025, # .{6}
  }, # [154]
  {
    amount           => "0.87053872", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7597.87",    # .{3}
    gross_price_usd  => "7597.87",    # .{4}
    net_price_orig   => 7578.875325,  # .{5}
    net_price_usd    => 7578.875325,  # .{6}
  }, # [155]
  {
    amount           => "0.6952407", # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7597.24",   # .{3}
    gross_price_usd  => "7597.24",   # .{4}
    net_price_orig   => 7578.2469,   # .{5}
    net_price_usd    => 7578.2469,   # .{6}
  }, # [156]
  {
    amount           => "0.001",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7597.09",   # .{3}
    gross_price_usd  => "7597.09",   # .{4}
    net_price_orig   => 7578.097275, # .{5}
    net_price_usd    => 7578.097275, # .{6}
  }, # [157]
  {
    amount           => "1.31438",   # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7597.05",   # .{3}
    gross_price_usd  => "7597.05",   # .{4}
    net_price_orig   => 7578.057375, # .{5}
    net_price_usd    => 7578.057375, # .{6}
  }, # [158]
  {
    amount           => "0.00315963", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7597",       # .{3}
    gross_price_usd  => "7597",       # .{4}
    net_price_orig   => 7578.0075,    # .{5}
    net_price_usd    => 7578.0075,    # .{6}
  }, # [159]
  {
    amount           => "0.328",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7596.77",   # .{3}
    gross_price_usd  => "7596.77",   # .{4}
    net_price_orig   => 7577.778075, # .{5}
    net_price_usd    => 7577.778075, # .{6}
  }, # [160]
  {
    amount           => "0.00584531",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105605000,     # .{3}
    gross_price_usd  => 7600.39185,    # .{4}
    net_price_orig   => 105288185,     # .{5}
    net_price_usd    => 7577.59067445, # .{6}
  }, # [161]
  {
    amount           => "1",        # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7596.46",  # .{3}
    gross_price_usd  => "7596.46",  # .{4}
    net_price_orig   => 7577.46885, # .{5}
    net_price_usd    => 7577.46885, # .{6}
  }, # [162]
  {
    amount           => "0.00053567",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105602000,     # .{3}
    gross_price_usd  => 7600.17594,    # .{4}
    net_price_orig   => 105285194,     # .{5}
    net_price_usd    => 7577.37541218, # .{6}
  }, # [163]
  {
    amount           => "0.11628045", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 105600000,    # .{3}
    gross_price_usd  => 7600.032,     # .{4}
    net_price_orig   => 105283200,    # .{5}
    net_price_usd    => 7577.231904,  # .{6}
  }, # [164]
  {
    amount           => "0.01",      # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7596.03",   # .{3}
    gross_price_usd  => "7596.03",   # .{4}
    net_price_orig   => 7577.039925, # .{5}
    net_price_usd    => 7577.039925, # .{6}
  }, # [165]
  {
    amount           => "0.0131", # .{0}
    currency         => "USD",    # .{1}
    exchange         => "gdax",   # .{2}
    gross_price_orig => "7596",   # .{3}
    gross_price_usd  => "7596",   # .{4}
    net_price_orig   => 7577.01,  # .{5}
    net_price_usd    => 7577.01,  # .{6}
  }, # [166]
  {
    amount           => "7.17524511", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7595.91",    # .{3}
    gross_price_usd  => "7595.91",    # .{4}
    net_price_orig   => 7576.920225,  # .{5}
    net_price_usd    => 7576.920225,  # .{6}
  }, # [167]
  {
    amount           => "0.001",   # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7595.8",  # .{3}
    gross_price_usd  => "7595.8",  # .{4}
    net_price_orig   => 7576.8105, # .{5}
    net_price_usd    => 7576.8105, # .{6}
  }, # [168]
  {
    amount           => "0.001",   # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7595.68", # .{3}
    gross_price_usd  => "7595.68", # .{4}
    net_price_orig   => 7576.6908, # .{5}
    net_price_usd    => 7576.6908, # .{6}
  }, # [169]
  {
    amount           => "4.703001", # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7595.46",  # .{3}
    gross_price_usd  => "7595.46",  # .{4}
    net_price_orig   => 7576.47135, # .{5}
    net_price_usd    => 7576.47135, # .{6}
  }, # [170]
  {
    amount           => "0.001",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7595.31",   # .{3}
    gross_price_usd  => "7595.31",   # .{4}
    net_price_orig   => 7576.321725, # .{5}
    net_price_usd    => 7576.321725, # .{6}
  }, # [171]
  {
    amount           => "0.00194881",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105585000,     # .{3}
    gross_price_usd  => 7598.95245,    # .{4}
    net_price_orig   => 105268245,     # .{5}
    net_price_usd    => 7576.15559265, # .{6}
  }, # [172]
  {
    amount           => "5.63613896", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7595",       # .{3}
    gross_price_usd  => "7595",       # .{4}
    net_price_orig   => 7576.0125,    # .{5}
    net_price_usd    => 7576.0125,    # .{6}
  }, # [173]
  {
    amount           => "0.00111916", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7594.99",    # .{3}
    gross_price_usd  => "7594.99",    # .{4}
    net_price_orig   => 7576.002525,  # .{5}
    net_price_usd    => 7576.002525,  # .{6}
  }, # [174]
  {
    amount           => "1.00208918", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7594",       # .{3}
    gross_price_usd  => "7594",       # .{4}
    net_price_orig   => 7575.015,     # .{5}
    net_price_usd    => 7575.015,     # .{6}
  }, # [175]
  {
    amount           => "0.00103325",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 105568000,     # .{3}
    gross_price_usd  => 7597.72896,    # .{4}
    net_price_orig   => 105251296,     # .{5}
    net_price_usd    => 7574.93577312, # .{6}
  }, # [176]
  {
    amount           => "0.5",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7592.73",   # .{3}
    gross_price_usd  => "7592.73",   # .{4}
    net_price_orig   => 7573.748175, # .{5}
    net_price_usd    => 7573.748175, # .{6}
  }, # [177]
  {
    amount           => "0.001",   # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7592.52", # .{3}
    gross_price_usd  => "7592.52", # .{4}
    net_price_orig   => 7573.5387, # .{5}
    net_price_usd    => 7573.5387, # .{6}
  }, # [178]
  {
    amount           => "8.8",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7591.75",   # .{3}
    gross_price_usd  => "7591.75",   # .{4}
    net_price_orig   => 7572.770625, # .{5}
    net_price_usd    => 7572.770625, # .{6}
  }, # [179]
  {
    amount           => "0.001",    # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7591.74",  # .{3}
    gross_price_usd  => "7591.74",  # .{4}
    net_price_orig   => 7572.76065, # .{5}
    net_price_usd    => 7572.76065, # .{6}
  }, # [180]
  {
    amount           => "0.001",  # .{0}
    currency         => "USD",    # .{1}
    exchange         => "gdax",   # .{2}
    gross_price_orig => "7591.6", # .{3}
    gross_price_usd  => "7591.6", # .{4}
    net_price_orig   => 7572.621, # .{5}
    net_price_usd    => 7572.621, # .{6}
  }, # [181]
  {
    amount           => "0.001",  # .{0}
    currency         => "USD",    # .{1}
    exchange         => "gdax",   # .{2}
    gross_price_orig => "7590.8", # .{3}
    gross_price_usd  => "7590.8", # .{4}
    net_price_orig   => 7571.823, # .{5}
    net_price_usd    => 7571.823, # .{6}
  }, # [182]
  {
    amount           => "0.0031628", # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7590.56",   # .{3}
    gross_price_usd  => "7590.56",   # .{4}
    net_price_orig   => 7571.5836,   # .{5}
    net_price_usd    => 7571.5836,   # .{6}
  }, # [183]
  {
    amount           => "0.01976154", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7590.5",     # .{3}
    gross_price_usd  => "7590.5",     # .{4}
    net_price_orig   => 7571.52375,   # .{5}
    net_price_usd    => 7571.52375,   # .{6}
  }, # [184]
  {
    amount           => "0.06637902", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7590.16",    # .{3}
    gross_price_usd  => "7590.16",    # .{4}
    net_price_orig   => 7571.1846,    # .{5}
    net_price_usd    => 7571.1846,    # .{6}
  }, # [185]
  {
    amount           => "7.75263031", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7590",       # .{3}
    gross_price_usd  => "7590",       # .{4}
    net_price_orig   => 7571.025,     # .{5}
    net_price_usd    => 7571.025,     # .{6}
  }, # [186]
  {
    amount           => "1",       # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7588.76", # .{3}
    gross_price_usd  => "7588.76", # .{4}
    net_price_orig   => 7569.7881, # .{5}
    net_price_usd    => 7569.7881, # .{6}
  }, # [187]
  {
    amount           => "1.918",    # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7588.62",  # .{3}
    gross_price_usd  => "7588.62",  # .{4}
    net_price_orig   => 7569.64845, # .{5}
    net_price_usd    => 7569.64845, # .{6}
  }, # [188]
  {
    amount           => "5.3",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7588.55",   # .{3}
    gross_price_usd  => "7588.55",   # .{4}
    net_price_orig   => 7569.578625, # .{5}
    net_price_usd    => 7569.578625, # .{6}
  }, # [189]
  {
    amount           => "1.403",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7588.37",   # .{3}
    gross_price_usd  => "7588.37",   # .{4}
    net_price_orig   => 7569.399075, # .{5}
    net_price_usd    => 7569.399075, # .{6}
  }, # [190]
  {
    amount           => "0.54962376", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7587.91",    # .{3}
    gross_price_usd  => "7587.91",    # .{4}
    net_price_orig   => 7568.940225,  # .{5}
    net_price_usd    => 7568.940225,  # .{6}
  }, # [191]
  {
    amount           => "0.00316438", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7587.54",    # .{3}
    gross_price_usd  => "7587.54",    # .{4}
    net_price_orig   => 7568.57115,   # .{5}
    net_price_usd    => 7568.57115,   # .{6}
  }, # [192]
  {
    amount           => "0.0023",   # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7587.5",   # .{3}
    gross_price_usd  => "7587.5",   # .{4}
    net_price_orig   => 7568.53125, # .{5}
    net_price_usd    => 7568.53125, # .{6}
  }, # [193]
  {
    amount           => "1.9",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7585.89",   # .{3}
    gross_price_usd  => "7585.89",   # .{4}
    net_price_orig   => 7566.925275, # .{5}
    net_price_usd    => 7566.925275, # .{6}
  }, # [194]
  {
    amount           => "1.8",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7585.79",   # .{3}
    gross_price_usd  => "7585.79",   # .{4}
    net_price_orig   => 7566.825525, # .{5}
    net_price_usd    => 7566.825525, # .{6}
  }, # [195]
  {
    amount           => "0.065914",  # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7585.67",   # .{3}
    gross_price_usd  => "7585.67",   # .{4}
    net_price_orig   => 7566.705825, # .{5}
    net_price_usd    => 7566.705825, # .{6}
  }, # [196]
  {
    amount           => "0.9",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7585.23",   # .{3}
    gross_price_usd  => "7585.23",   # .{4}
    net_price_orig   => 7566.266925, # .{5}
    net_price_usd    => 7566.266925, # .{6}
  }, # [197]
  {
    amount           => "1.80068775", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7585",       # .{3}
    gross_price_usd  => "7585",       # .{4}
    net_price_orig   => 7566.0375,    # .{5}
    net_price_usd    => 7566.0375,    # .{6}
  }, # [198]
  {
    amount           => "8.6",      # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7584.22",  # .{3}
    gross_price_usd  => "7584.22",  # .{4}
    net_price_orig   => 7565.25945, # .{5}
    net_price_usd    => 7565.25945, # .{6}
  }, # [199]
];

my $all_sell_orders0 = [
  {
    amount           => "2.53543601", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7601",       # .{3}
    gross_price_usd  => "7601",       # .{4}
    net_price_orig   => 7620.0025,    # .{5}
    net_price_usd    => 7620.0025,    # .{6}
  }, # [  0]
  {
    amount           => "1.02956919", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7603",       # .{3}
    gross_price_usd  => "7603",       # .{4}
    net_price_orig   => 7622.0075,    # .{5}
    net_price_usd    => 7622.0075,    # .{6}
  }, # [  1]
  {
    amount           => "2.501",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7603.01",   # .{3}
    gross_price_usd  => "7603.01",   # .{4}
    net_price_orig   => 7622.017525, # .{5}
    net_price_usd    => 7622.017525, # .{6}
  }, # [  2]
  {
    amount           => "2.5",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7603.47",   # .{3}
    gross_price_usd  => "7603.47",   # .{4}
    net_price_orig   => 7622.478675, # .{5}
    net_price_usd    => 7622.478675, # .{6}
  }, # [  3]
  {
    amount           => "0.086",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7603.73",   # .{3}
    gross_price_usd  => "7603.73",   # .{4}
    net_price_orig   => 7622.739325, # .{5}
    net_price_usd    => 7622.739325, # .{6}
  }, # [  4]
  {
    amount           => "0.086",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7603.77",   # .{3}
    gross_price_usd  => "7603.77",   # .{4}
    net_price_orig   => 7622.779425, # .{5}
    net_price_usd    => 7622.779425, # .{6}
  }, # [  5]
  {
    amount           => "0.086",   # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7603.88", # .{3}
    gross_price_usd  => "7603.88", # .{4}
    net_price_orig   => 7622.8897, # .{5}
    net_price_usd    => 7622.8897, # .{6}
  }, # [  6]
  {
    amount           => "2.086",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7603.93",   # .{3}
    gross_price_usd  => "7603.93",   # .{4}
    net_price_orig   => 7622.939825, # .{5}
    net_price_usd    => 7622.939825, # .{6}
  }, # [  7]
  {
    amount           => "0.086",   # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7604.04", # .{3}
    gross_price_usd  => "7604.04", # .{4}
    net_price_orig   => 7623.0501, # .{5}
    net_price_usd    => 7623.0501, # .{6}
  }, # [  8]
  {
    amount           => "0.0407",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7605.51",   # .{3}
    gross_price_usd  => "7605.51",   # .{4}
    net_price_orig   => 7624.523775, # .{5}
    net_price_usd    => 7624.523775, # .{6}
  }, # [  9]
  {
    amount           => "0.25",     # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7605.7",   # .{3}
    gross_price_usd  => "7605.7",   # .{4}
    net_price_orig   => 7624.71425, # .{5}
    net_price_usd    => 7624.71425, # .{6}
  }, # [ 10]
  {
    amount           => "0.0407",  # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7605.8",  # .{3}
    gross_price_usd  => "7605.8",  # .{4}
    net_price_orig   => 7624.8145, # .{5}
    net_price_usd    => 7624.8145, # .{6}
  }, # [ 11]
  {
    amount           => "0.0507",   # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7606.34",  # .{3}
    gross_price_usd  => "7606.34",  # .{4}
    net_price_orig   => 7625.35585, # .{5}
    net_price_usd    => 7625.35585, # .{6}
  }, # [ 12]
  {
    amount           => "0.026",   # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7606.36", # .{3}
    gross_price_usd  => "7606.36", # .{4}
    net_price_orig   => 7625.3759, # .{5}
    net_price_usd    => 7625.3759, # .{6}
  }, # [ 13]
  {
    amount           => "0.1533",   # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7606.66",  # .{3}
    gross_price_usd  => "7606.66",  # .{4}
    net_price_orig   => 7625.67665, # .{5}
    net_price_usd    => 7625.67665, # .{6}
  }, # [ 14]
  {
    amount           => "0.0407",  # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7606.76", # .{3}
    gross_price_usd  => "7606.76", # .{4}
    net_price_orig   => 7625.7769, # .{5}
    net_price_usd    => 7625.7769, # .{6}
  }, # [ 15]
  {
    amount           => "0.0267",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7607.83",   # .{3}
    gross_price_usd  => "7607.83",   # .{4}
    net_price_orig   => 7626.849575, # .{5}
    net_price_usd    => 7626.849575, # .{6}
  }, # [ 16]
  {
    amount           => "0.0407",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7608.39",   # .{3}
    gross_price_usd  => "7608.39",   # .{4}
    net_price_orig   => 7627.410975, # .{5}
    net_price_usd    => 7627.410975, # .{6}
  }, # [ 17]
  {
    amount           => "0.0407",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7608.47",   # .{3}
    gross_price_usd  => "7608.47",   # .{4}
    net_price_orig   => 7627.491175, # .{5}
    net_price_usd    => 7627.491175, # .{6}
  }, # [ 18]
  {
    amount           => "0.0407",  # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7608.92", # .{3}
    gross_price_usd  => "7608.92", # .{4}
    net_price_orig   => 7627.9423, # .{5}
    net_price_usd    => 7627.9423, # .{6}
  }, # [ 19]
  {
    amount           => "2.006",   # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7609",    # .{3}
    gross_price_usd  => "7609",    # .{4}
    net_price_orig   => 7628.0225, # .{5}
    net_price_usd    => 7628.0225, # .{6}
  }, # [ 20]
  {
    amount           => "0.0407",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7609.41",   # .{3}
    gross_price_usd  => "7609.41",   # .{4}
    net_price_orig   => 7628.433525, # .{5}
    net_price_usd    => 7628.433525, # .{6}
  }, # [ 21]
  {
    amount           => "0.0407",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7609.95",   # .{3}
    gross_price_usd  => "7609.95",   # .{4}
    net_price_orig   => 7628.974875, # .{5}
    net_price_usd    => 7628.974875, # .{6}
  }, # [ 22]
  {
    amount           => "0.0333",  # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7610.12", # .{3}
    gross_price_usd  => "7610.12", # .{4}
    net_price_orig   => 7629.1453, # .{5}
    net_price_usd    => 7629.1453, # .{6}
  }, # [ 23]
  {
    amount           => "0.0407",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7610.55",   # .{3}
    gross_price_usd  => "7610.55",   # .{4}
    net_price_orig   => 7629.576375, # .{5}
    net_price_usd    => 7629.576375, # .{6}
  }, # [ 24]
  {
    amount           => "0.003",    # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7611.46",  # .{3}
    gross_price_usd  => "7611.46",  # .{4}
    net_price_orig   => 7630.48865, # .{5}
    net_price_usd    => 7630.48865, # .{6}
  }, # [ 25]
  {
    amount           => "0.001",    # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7611.82",  # .{3}
    gross_price_usd  => "7611.82",  # .{4}
    net_price_orig   => 7630.84955, # .{5}
    net_price_usd    => 7630.84955, # .{6}
  }, # [ 26]
  {
    amount           => "0.01",  # .{0}
    currency         => "USD",   # .{1}
    exchange         => "gdax",  # .{2}
    gross_price_orig => "7612",  # .{3}
    gross_price_usd  => "7612",  # .{4}
    net_price_orig   => 7631.03, # .{5}
    net_price_usd    => 7631.03, # .{6}
  }, # [ 27]
  {
    amount           => "0.0023",   # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7612.5",   # .{3}
    gross_price_usd  => "7612.5",   # .{4}
    net_price_orig   => 7631.53125, # .{5}
    net_price_usd    => 7631.53125, # .{6}
  }, # [ 28]
  {
    amount           => "0.0338",    # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7614.25",   # .{3}
    gross_price_usd  => "7614.25",   # .{4}
    net_price_orig   => 7633.285625, # .{5}
    net_price_usd    => 7633.285625, # .{6}
  }, # [ 29]
  {
    amount           => "0.0351",   # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7614.26",  # .{3}
    gross_price_usd  => "7614.26",  # .{4}
    net_price_orig   => 7633.29565, # .{5}
    net_price_usd    => 7633.29565, # .{6}
  }, # [ 30]
  {
    amount           => "1",       # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7614.92", # .{3}
    gross_price_usd  => "7614.92", # .{4}
    net_price_orig   => 7633.9573, # .{5}
    net_price_usd    => 7633.9573, # .{6}
  }, # [ 31]
  {
    amount           => "1.924",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7614.93",   # .{3}
    gross_price_usd  => "7614.93",   # .{4}
    net_price_orig   => 7633.967325, # .{5}
    net_price_usd    => 7633.967325, # .{6}
  }, # [ 32]
  {
    amount           => "1.002",    # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7614.94",  # .{3}
    gross_price_usd  => "7614.94",  # .{4}
    net_price_orig   => 7633.97735, # .{5}
    net_price_usd    => 7633.97735, # .{6}
  }, # [ 33]
  {
    amount           => "0.09496899", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7615",       # .{3}
    gross_price_usd  => "7615",       # .{4}
    net_price_orig   => 7634.0375,    # .{5}
    net_price_usd    => 7634.0375,    # .{6}
  }, # [ 34]
  {
    amount           => "0.5",     # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7615.28", # .{3}
    gross_price_usd  => "7615.28", # .{4}
    net_price_orig   => 7634.3182, # .{5}
    net_price_usd    => 7634.3182, # .{6}
  }, # [ 35]
  {
    amount           => "0.892",   # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7616.2",  # .{3}
    gross_price_usd  => "7616.2",  # .{4}
    net_price_orig   => 7635.2405, # .{5}
    net_price_usd    => 7635.2405, # .{6}
  }, # [ 36]
  {
    amount           => "1.799998",  # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7616.21",   # .{3}
    gross_price_usd  => "7616.21",   # .{4}
    net_price_orig   => 7635.250525, # .{5}
    net_price_usd    => 7635.250525, # .{6}
  }, # [ 37]
  {
    amount           => "0.001",   # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7617.28", # .{3}
    gross_price_usd  => "7617.28", # .{4}
    net_price_orig   => 7636.3232, # .{5}
    net_price_usd    => 7636.3232, # .{6}
  }, # [ 38]
  {
    amount           => "0.00559256", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7617.44",    # .{3}
    gross_price_usd  => "7617.44",    # .{4}
    net_price_orig   => 7636.4836,    # .{5}
    net_price_usd    => 7636.4836,    # .{6}
  }, # [ 39]
  {
    amount           => "0.8",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7618.05",   # .{3}
    gross_price_usd  => "7618.05",   # .{4}
    net_price_orig   => 7637.095125, # .{5}
    net_price_usd    => 7637.095125, # .{6}
  }, # [ 40]
  {
    amount           => "9.15",     # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7618.06",  # .{3}
    gross_price_usd  => "7618.06",  # .{4}
    net_price_orig   => 7637.10515, # .{5}
    net_price_usd    => 7637.10515, # .{6}
  }, # [ 41]
  {
    amount           => "0.0015",  # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7618.44", # .{3}
    gross_price_usd  => "7618.44", # .{4}
    net_price_orig   => 7637.4861, # .{5}
    net_price_usd    => 7637.4861, # .{6}
  }, # [ 42]
  {
    amount           => "0.22",      # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7618.45",   # .{3}
    gross_price_usd  => "7618.45",   # .{4}
    net_price_orig   => 7637.496125, # .{5}
    net_price_usd    => 7637.496125, # .{6}
  }, # [ 43]
  {
    amount           => "0.9",       # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7618.49",   # .{3}
    gross_price_usd  => "7618.49",   # .{4}
    net_price_orig   => 7637.536225, # .{5}
    net_price_usd    => 7637.536225, # .{6}
  }, # [ 44]
  {
    amount           => "12",      # .{0}
    currency         => "USD",     # .{1}
    exchange         => "gdax",    # .{2}
    gross_price_orig => "7618.76", # .{3}
    gross_price_usd  => "7618.76", # .{4}
    net_price_orig   => 7637.8069, # .{5}
    net_price_usd    => 7637.8069, # .{6}
  }, # [ 45]
  {
    amount           => "0.11929733", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7619",       # .{3}
    gross_price_usd  => "7619",       # .{4}
    net_price_orig   => 7638.0475,    # .{5}
    net_price_usd    => 7638.0475,    # .{6}
  }, # [ 46]
  {
    amount           => "1.554",    # .{0}
    currency         => "USD",      # .{1}
    exchange         => "gdax",     # .{2}
    gross_price_orig => "7619.54",  # .{3}
    gross_price_usd  => "7619.54",  # .{4}
    net_price_orig   => 7638.58885, # .{5}
    net_price_usd    => 7638.58885, # .{6}
  }, # [ 47]
  {
    amount           => "0.025",     # .{0}
    currency         => "USD",       # .{1}
    exchange         => "gdax",      # .{2}
    gross_price_orig => "7619.99",   # .{3}
    gross_price_usd  => "7619.99",   # .{4}
    net_price_orig   => 7639.039975, # .{5}
    net_price_usd    => 7639.039975, # .{6}
  }, # [ 48]
  {
    amount           => "6.96170038", # .{0}
    currency         => "USD",        # .{1}
    exchange         => "gdax",       # .{2}
    gross_price_orig => "7620",       # .{3}
    gross_price_usd  => "7620",       # .{4}
    net_price_orig   => 7639.05,      # .{5}
    net_price_usd    => 7639.05,      # .{6}
  }, # [ 49]
  {
    amount           => "0.20583919",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => "107315000",   # .{3}
    gross_price_usd  => 7706.29015,    # .{4}
    net_price_orig   => 107636945,     # .{5}
    net_price_usd    => 7729.40902045, # .{6}
  }, # [ 50]
  {
    amount           => "2.40050776",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107349000,     # .{3}
    gross_price_usd  => 7708.73169,    # .{4}
    net_price_orig   => 107671047,     # .{5}
    net_price_usd    => 7731.85788507, # .{6}
  }, # [ 51]
  {
    amount           => "0.00880935", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107350000,    # .{3}
    gross_price_usd  => 7708.8035,    # .{4}
    net_price_orig   => 107672050,    # .{5}
    net_price_usd    => 7731.9299105, # .{6}
  }, # [ 52]
  {
    amount           => "0.00011000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107355000,     # .{3}
    gross_price_usd  => 7709.16255,    # .{4}
    net_price_orig   => 107677065,     # .{5}
    net_price_usd    => 7732.29003765, # .{6}
  }, # [ 53]
  {
    amount           => "0.02300354",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107369000,     # .{3}
    gross_price_usd  => 7710.16789,    # .{4}
    net_price_orig   => 107691107,     # .{5}
    net_price_usd    => 7733.29839367, # .{6}
  }, # [ 54]
  {
    amount           => "0.01084732", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107370000,    # .{3}
    gross_price_usd  => 7710.2397,    # .{4}
    net_price_orig   => 107692110,    # .{5}
    net_price_usd    => 7733.3704191, # .{6}
  }, # [ 55]
  {
    amount           => "0.08224409",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107398000,     # .{3}
    gross_price_usd  => 7712.25038,    # .{4}
    net_price_orig   => 107720194,     # .{5}
    net_price_usd    => 7735.38713114, # .{6}
  }, # [ 56]
  {
    amount           => "0.09985832",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107399000,     # .{3}
    gross_price_usd  => 7712.32219,    # .{4}
    net_price_orig   => 107721197,     # .{5}
    net_price_usd    => 7735.45915657, # .{6}
  }, # [ 57]
  {
    amount           => "0.07959631", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107400000,    # .{3}
    gross_price_usd  => 7712.394,     # .{4}
    net_price_orig   => 107722200,    # .{5}
    net_price_usd    => 7735.531182,  # .{6}
  }, # [ 58]
  {
    amount           => "1.94640000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107497000,     # .{3}
    gross_price_usd  => 7719.35957,    # .{4}
    net_price_orig   => 107819491,     # .{5}
    net_price_usd    => 7742.51764871, # .{6}
  }, # [ 59]
  {
    amount           => "0.08751395",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107498000,     # .{3}
    gross_price_usd  => 7719.43138,    # .{4}
    net_price_orig   => 107820494,     # .{5}
    net_price_usd    => 7742.58967414, # .{6}
  }, # [ 60]
  {
    amount           => "0.02689788", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107500000,    # .{3}
    gross_price_usd  => 7719.575,     # .{4}
    net_price_orig   => 107822500,    # .{5}
    net_price_usd    => 7742.733725,  # .{6}
  }, # [ 61]
  {
    amount           => "0.00253086",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107532000,     # .{3}
    gross_price_usd  => 7721.87292,    # .{4}
    net_price_orig   => 107854596,     # .{5}
    net_price_usd    => 7745.03853876, # .{6}
  }, # [ 62]
  {
    amount           => "0.00978819", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107550000,    # .{3}
    gross_price_usd  => 7723.1655,    # .{4}
    net_price_orig   => 107872650,    # .{5}
    net_price_usd    => 7746.3349965, # .{6}
  }, # [ 63]
  {
    amount           => "0.01620017", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107560000,    # .{3}
    gross_price_usd  => 7723.8836,    # .{4}
    net_price_orig   => 107882680,    # .{5}
    net_price_usd    => 7747.0552508, # .{6}
  }, # [ 64]
  {
    amount           => "0.00398763",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107567000,     # .{3}
    gross_price_usd  => 7724.38627,    # .{4}
    net_price_orig   => 107889701,     # .{5}
    net_price_usd    => 7747.55942881, # .{6}
  }, # [ 65]
  {
    amount           => "0.01886196",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107579000,     # .{3}
    gross_price_usd  => 7725.24799,    # .{4}
    net_price_orig   => 107901737,     # .{5}
    net_price_usd    => 7748.42373397, # .{6}
  }, # [ 66]
  {
    amount           => "0.04632314", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107580000,    # .{3}
    gross_price_usd  => 7725.3198,    # .{4}
    net_price_orig   => 107902740,    # .{5}
    net_price_usd    => 7748.4957594, # .{6}
  }, # [ 67]
  {
    amount           => "0.09332353",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107586000,     # .{3}
    gross_price_usd  => 7725.75066,    # .{4}
    net_price_orig   => 107908758,     # .{5}
    net_price_usd    => 7748.92791198, # .{6}
  }, # [ 68]
  {
    amount           => "0.82983580", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107600000,    # .{3}
    gross_price_usd  => 7726.756,     # .{4}
    net_price_orig   => 107922800,    # .{5}
    net_price_usd    => 7749.936268,  # .{6}
  }, # [ 69]
  {
    amount           => "0.00247919",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107699000,     # .{3}
    gross_price_usd  => 7733.86519,    # .{4}
    net_price_orig   => 108022097,     # .{5}
    net_price_usd    => 7757.06678557, # .{6}
  }, # [ 70]
  {
    amount           => "2.99663681", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107700000,    # .{3}
    gross_price_usd  => 7733.937,     # .{4}
    net_price_orig   => 108023100,    # .{5}
    net_price_usd    => 7757.138811,  # .{6}
  }, # [ 71]
  {
    amount           => "0.01629413",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107714000,     # .{3}
    gross_price_usd  => 7734.94234,    # .{4}
    net_price_orig   => 108037142,     # .{5}
    net_price_usd    => 7758.14716702, # .{6}
  }, # [ 72]
  {
    amount           => "0.00196273", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107720000,    # .{3}
    gross_price_usd  => 7735.3732,    # .{4}
    net_price_orig   => 108043160,    # .{5}
    net_price_usd    => 7758.5793196, # .{6}
  }, # [ 73]
  {
    amount           => "0.05075000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107722000,     # .{3}
    gross_price_usd  => 7735.51682,    # .{4}
    net_price_orig   => 108045166,     # .{5}
    net_price_usd    => 7758.72337046, # .{6}
  }, # [ 74]
  {
    amount           => "0.00030662",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107724000,     # .{3}
    gross_price_usd  => 7735.66044,    # .{4}
    net_price_orig   => 108047172,     # .{5}
    net_price_usd    => 7758.86742132, # .{6}
  }, # [ 75]
  {
    amount           => "0.00196920",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107729000,     # .{3}
    gross_price_usd  => 7736.01949,    # .{4}
    net_price_orig   => 108052187,     # .{5}
    net_price_usd    => 7759.22754847, # .{6}
  }, # [ 76]
  {
    amount           => "0.00091929", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107730000,    # .{3}
    gross_price_usd  => 7736.0913,    # .{4}
    net_price_orig   => 108053190,    # .{5}
    net_price_usd    => 7759.2995739, # .{6}
  }, # [ 77]
  {
    amount           => "0.00088614", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107740000,    # .{3}
    gross_price_usd  => 7736.8094,    # .{4}
    net_price_orig   => 108063220,    # .{5}
    net_price_usd    => 7760.0198282, # .{6}
  }, # [ 78]
  {
    amount           => "0.09310876", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107750000,    # .{3}
    gross_price_usd  => 7737.5275,    # .{4}
    net_price_orig   => 108073250,    # .{5}
    net_price_usd    => 7760.7400825, # .{6}
  }, # [ 79]
  {
    amount           => "0.00500000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107751000,     # .{3}
    gross_price_usd  => 7737.59931,    # .{4}
    net_price_orig   => 108074253,     # .{5}
    net_price_usd    => 7760.81210793, # .{6}
  }, # [ 80]
  {
    amount           => "0.00275799", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107770000,    # .{3}
    gross_price_usd  => 7738.9637,    # .{4}
    net_price_orig   => 108093310,    # .{5}
    net_price_usd    => 7762.1805911, # .{6}
  }, # [ 81]
  {
    amount           => "0.02912654", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107780000,    # .{3}
    gross_price_usd  => 7739.6818,    # .{4}
    net_price_orig   => 108103340,    # .{5}
    net_price_usd    => 7762.9008454, # .{6}
  }, # [ 82]
  {
    amount           => "0.00582944",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107793000,     # .{3}
    gross_price_usd  => 7740.61533,    # .{4}
    net_price_orig   => 108116379,     # .{5}
    net_price_usd    => 7763.83717599, # .{6}
  }, # [ 83]
  {
    amount           => "0.09218677", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107800000,    # .{3}
    gross_price_usd  => 7741.118,     # .{4}
    net_price_orig   => 108123400,    # .{5}
    net_price_usd    => 7764.341354,  # .{6}
  }, # [ 84]
  {
    amount           => "0.41182766",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107801000,     # .{3}
    gross_price_usd  => 7741.18981,    # .{4}
    net_price_orig   => 108124403,     # .{5}
    net_price_usd    => 7764.41337943, # .{6}
  }, # [ 85]
  {
    amount           => "0.00646500",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107803000,     # .{3}
    gross_price_usd  => 7741.33343,    # .{4}
    net_price_orig   => 108126409,     # .{5}
    net_price_usd    => 7764.55743029, # .{6}
  }, # [ 86]
  {
    amount           => "0.00085455",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107805000,     # .{3}
    gross_price_usd  => 7741.47705,    # .{4}
    net_price_orig   => 108128415,     # .{5}
    net_price_usd    => 7764.70148115, # .{6}
  }, # [ 87]
  {
    amount           => "0.00475447",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107815000,     # .{3}
    gross_price_usd  => 7742.19515,    # .{4}
    net_price_orig   => 108138445,     # .{5}
    net_price_usd    => 7765.42173545, # .{6}
  }, # [ 88]
  {
    amount           => "0.00087092",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107818000,     # .{3}
    gross_price_usd  => 7742.41058,    # .{4}
    net_price_orig   => 108141454,     # .{5}
    net_price_usd    => 7765.63781174, # .{6}
  }, # [ 89]
  {
    amount           => "0.04891238",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107835000,     # .{3}
    gross_price_usd  => 7743.63135,    # .{4}
    net_price_orig   => 108158505,     # .{5}
    net_price_usd    => 7766.86224405, # .{6}
  }, # [ 90]
  {
    amount           => "0.00315710",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107836000,     # .{3}
    gross_price_usd  => 7743.70316,    # .{4}
    net_price_orig   => 108159508,     # .{5}
    net_price_usd    => 7766.93426948, # .{6}
  }, # [ 91]
  {
    amount           => "0.00264027", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107850000,    # .{3}
    gross_price_usd  => 7744.7085,    # .{4}
    net_price_orig   => 108173550,    # .{5}
    net_price_usd    => 7767.9426255, # .{6}
  }, # [ 92]
  {
    amount           => "0.00051111",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107864000,     # .{3}
    gross_price_usd  => 7745.71384,    # .{4}
    net_price_orig   => 108187592,     # .{5}
    net_price_usd    => 7768.95098152, # .{6}
  }, # [ 93]
  {
    amount           => "0.00093932",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107881000,     # .{3}
    gross_price_usd  => 7746.93461,    # .{4}
    net_price_orig   => 108204643,     # .{5}
    net_price_usd    => 7770.17541383, # .{6}
  }, # [ 94]
  {
    amount           => "0.01000000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107888000,     # .{3}
    gross_price_usd  => 7747.43728,    # .{4}
    net_price_orig   => 108211664,     # .{5}
    net_price_usd    => 7770.67959184, # .{6}
  }, # [ 95]
  {
    amount           => "0.00600000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107893000,     # .{3}
    gross_price_usd  => 7747.79633,    # .{4}
    net_price_orig   => 108216679,     # .{5}
    net_price_usd    => 7771.03971899, # .{6}
  }, # [ 96]
  {
    amount           => "0.00100000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107894000,     # .{3}
    gross_price_usd  => 7747.86814,    # .{4}
    net_price_orig   => 108217682,     # .{5}
    net_price_usd    => 7771.11174442, # .{6}
  }, # [ 97]
  {
    amount           => "0.00300000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107899000,     # .{3}
    gross_price_usd  => 7748.22719,    # .{4}
    net_price_orig   => 108222697,     # .{5}
    net_price_usd    => 7771.47187157, # .{6}
  }, # [ 98]
  {
    amount           => "0.13264995", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107900000,    # .{3}
    gross_price_usd  => 7748.299,     # .{4}
    net_price_orig   => 108223700,    # .{5}
    net_price_usd    => 7771.543897,  # .{6}
  }, # [ 99]
  {
    amount           => "0.41096917",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107901000,     # .{3}
    gross_price_usd  => 7748.37081,    # .{4}
    net_price_orig   => 108224703,     # .{5}
    net_price_usd    => 7771.61592243, # .{6}
  }, # [100]
  {
    amount           => "0.10987113",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107902000,     # .{3}
    gross_price_usd  => 7748.44262,    # .{4}
    net_price_orig   => 108225706,     # .{5}
    net_price_usd    => 7771.68794786, # .{6}
  }, # [101]
  {
    amount           => "0.05000000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107931000,     # .{3}
    gross_price_usd  => 7750.52511,    # .{4}
    net_price_orig   => 108254793,     # .{5}
    net_price_usd    => 7773.77668533, # .{6}
  }, # [102]
  {
    amount           => "0.00122666",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107933000,     # .{3}
    gross_price_usd  => 7750.66873,    # .{4}
    net_price_orig   => 108256799,     # .{5}
    net_price_usd    => 7773.92073619, # .{6}
  }, # [103]
  {
    amount           => "0.00499173",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107934000,     # .{3}
    gross_price_usd  => 7750.74054,    # .{4}
    net_price_orig   => 108257802,     # .{5}
    net_price_usd    => 7773.99276162, # .{6}
  }, # [104]
  {
    amount           => "0.00139242",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107942000,     # .{3}
    gross_price_usd  => 7751.31502,    # .{4}
    net_price_orig   => 108265826,     # .{5}
    net_price_usd    => 7774.56896506, # .{6}
  }, # [105]
  {
    amount           => "0.00278478",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107944000,     # .{3}
    gross_price_usd  => 7751.45864,    # .{4}
    net_price_orig   => 108267832,     # .{5}
    net_price_usd    => 7774.71301592, # .{6}
  }, # [106]
  {
    amount           => "0.02839012", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107950000,    # .{3}
    gross_price_usd  => 7751.8895,    # .{4}
    net_price_orig   => 108273850,    # .{5}
    net_price_usd    => 7775.1451685, # .{6}
  }, # [107]
  {
    amount           => "0.02083960",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107958000,     # .{3}
    gross_price_usd  => 7752.46398,    # .{4}
    net_price_orig   => 108281874,     # .{5}
    net_price_usd    => 7775.72137194, # .{6}
  }, # [108]
  {
    amount           => "0.00695950",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107982000,     # .{3}
    gross_price_usd  => 7754.18742,    # .{4}
    net_price_orig   => 108305946,     # .{5}
    net_price_usd    => 7777.44998226, # .{6}
  }, # [109]
  {
    amount           => "0.00278374",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107984000,     # .{3}
    gross_price_usd  => 7754.33104,    # .{4}
    net_price_orig   => 108307952,     # .{5}
    net_price_usd    => 7777.59403312, # .{6}
  }, # [110]
  {
    amount           => "0.00278372",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107985000,     # .{3}
    gross_price_usd  => 7754.40285,    # .{4}
    net_price_orig   => 108308955,     # .{5}
    net_price_usd    => 7777.66605855, # .{6}
  }, # [111]
  {
    amount           => "0.00697278", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 107990000,    # .{3}
    gross_price_usd  => 7754.7619,    # .{4}
    net_price_orig   => 108313970,    # .{5}
    net_price_usd    => 7778.0261857, # .{6}
  }, # [112]
  {
    amount           => "0.00950391",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107995000,     # .{3}
    gross_price_usd  => 7755.12095,    # .{4}
    net_price_orig   => 108318985,     # .{5}
    net_price_usd    => 7778.38631285, # .{6}
  }, # [113]
  {
    amount           => "0.00277900",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107997000,     # .{3}
    gross_price_usd  => 7755.26457,    # .{4}
    net_price_orig   => 108320991,     # .{5}
    net_price_usd    => 7778.53036371, # .{6}
  }, # [114]
  {
    amount           => "0.00171782",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 107999000,     # .{3}
    gross_price_usd  => 7755.40819,    # .{4}
    net_price_orig   => 108322997,     # .{5}
    net_price_usd    => 7778.67441457, # .{6}
  }, # [115]
  {
    amount           => "2.41711960", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108000000,    # .{3}
    gross_price_usd  => 7755.48,      # .{4}
    net_price_orig   => 108324000,    # .{5}
    net_price_usd    => 7778.74644,   # .{6}
  }, # [116]
  {
    amount           => "0.18555048",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108001000,     # .{3}
    gross_price_usd  => 7755.55181,    # .{4}
    net_price_orig   => 108325003,     # .{5}
    net_price_usd    => 7778.81846543, # .{6}
  }, # [117]
  {
    amount           => "0.14712145",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108005000,     # .{3}
    gross_price_usd  => 7755.83905,    # .{4}
    net_price_orig   => 108329015,     # .{5}
    net_price_usd    => 7779.10656715, # .{6}
  }, # [118]
  {
    amount           => "0.05174026",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108024000,     # .{3}
    gross_price_usd  => 7757.20344,    # .{4}
    net_price_orig   => 108348072,     # .{5}
    net_price_usd    => 7780.47505032, # .{6}
  }, # [119]
  {
    amount           => "0.02659625",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108037000,     # .{3}
    gross_price_usd  => 7758.13697,    # .{4}
    net_price_orig   => 108361111,     # .{5}
    net_price_usd    => 7781.41138091, # .{6}
  }, # [120]
  {
    amount           => "0.01000000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108043000,     # .{3}
    gross_price_usd  => 7758.56783,    # .{4}
    net_price_orig   => 108367129,     # .{5}
    net_price_usd    => 7781.84353349, # .{6}
  }, # [121]
  {
    amount           => "0.04678692", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108050000,    # .{3}
    gross_price_usd  => 7759.0705,    # .{4}
    net_price_orig   => 108374150,    # .{5}
    net_price_usd    => 7782.3477115, # .{6}
  }, # [122]
  {
    amount           => "0.03396879",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108059000,     # .{3}
    gross_price_usd  => 7759.71679,    # .{4}
    net_price_orig   => 108383177,     # .{5}
    net_price_usd    => 7782.99594037, # .{6}
  }, # [123]
  {
    amount           => "0.00759283",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108061000,     # .{3}
    gross_price_usd  => 7759.86041,    # .{4}
    net_price_orig   => 108385183,     # .{5}
    net_price_usd    => 7783.13999123, # .{6}
  }, # [124]
  {
    amount           => "0.00052556",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108064000,     # .{3}
    gross_price_usd  => 7760.07584,    # .{4}
    net_price_orig   => 108388192,     # .{5}
    net_price_usd    => 7783.35606752, # .{6}
  }, # [125]
  {
    amount           => "0.00096040",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108065000,     # .{3}
    gross_price_usd  => 7760.14765,    # .{4}
    net_price_orig   => 108389195,     # .{5}
    net_price_usd    => 7783.42809295, # .{6}
  }, # [126]
  {
    amount           => "0.04542508",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108066000,     # .{3}
    gross_price_usd  => 7760.21946,    # .{4}
    net_price_orig   => 108390198,     # .{5}
    net_price_usd    => 7783.50011838, # .{6}
  }, # [127]
  {
    amount           => "0.00139080",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108067000,     # .{3}
    gross_price_usd  => 7760.29127,    # .{4}
    net_price_orig   => 108391201,     # .{5}
    net_price_usd    => 7783.57214381, # .{6}
  }, # [128]
  {
    amount           => "0.01040125", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108070000,    # .{3}
    gross_price_usd  => 7760.5067,    # .{4}
    net_price_orig   => 108394210,    # .{5}
    net_price_usd    => 7783.7882201, # .{6}
  }, # [129]
  {
    amount           => "0.01483302",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108071000,     # .{3}
    gross_price_usd  => 7760.57851,    # .{4}
    net_price_orig   => 108395213,     # .{5}
    net_price_usd    => 7783.86024553, # .{6}
  }, # [130]
  {
    amount           => "0.00023037",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108078000,     # .{3}
    gross_price_usd  => 7761.08118,    # .{4}
    net_price_orig   => 108402234,     # .{5}
    net_price_usd    => 7784.36442354, # .{6}
  }, # [131]
  {
    amount           => "0.01431935", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108100000,    # .{3}
    gross_price_usd  => 7762.661,     # .{4}
    net_price_orig   => 108424300,    # .{5}
    net_price_usd    => 7785.948983,  # .{6}
  }, # [132]
  {
    amount           => "0.00426197",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108115000,     # .{3}
    gross_price_usd  => 7763.73815,    # .{4}
    net_price_orig   => 108439345,     # .{5}
    net_price_usd    => 7787.02936445, # .{6}
  }, # [133]
  {
    amount           => "0.00278032",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108117000,     # .{3}
    gross_price_usd  => 7763.88177,    # .{4}
    net_price_orig   => 108441351,     # .{5}
    net_price_usd    => 7787.17341531, # .{6}
  }, # [134]
  {
    amount           => "0.00133285",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108121000,     # .{3}
    gross_price_usd  => 7764.16901,    # .{4}
    net_price_orig   => 108445363,     # .{5}
    net_price_usd    => 7787.46151703, # .{6}
  }, # [135]
  {
    amount           => "0.00656399",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108148000,     # .{3}
    gross_price_usd  => 7766.10788,    # .{4}
    net_price_orig   => 108472444,     # .{5}
    net_price_usd    => 7789.40620364, # .{6}
  }, # [136]
  {
    amount           => "0.00098008", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108150000,    # .{3}
    gross_price_usd  => 7766.2515,    # .{4}
    net_price_orig   => 108474450,    # .{5}
    net_price_usd    => 7789.5502545, # .{6}
  }, # [137]
  {
    amount           => "0.00172329",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108159000,     # .{3}
    gross_price_usd  => 7766.89779,    # .{4}
    net_price_orig   => 108483477,     # .{5}
    net_price_usd    => 7790.19848337, # .{6}
  }, # [138]
  {
    amount           => "0.01346495",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108165000,     # .{3}
    gross_price_usd  => 7767.32865,    # .{4}
    net_price_orig   => 108489495,     # .{5}
    net_price_usd    => 7790.63063595, # .{6}
  }, # [139]
  {
    amount           => "0.00100000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108187000,     # .{3}
    gross_price_usd  => 7768.90847,    # .{4}
    net_price_orig   => 108511561,     # .{5}
    net_price_usd    => 7792.21519541, # .{6}
  }, # [140]
  {
    amount           => "0.00084699",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108197000,     # .{3}
    gross_price_usd  => 7769.62657,    # .{4}
    net_price_orig   => 108521591,     # .{5}
    net_price_usd    => 7792.93544971, # .{6}
  }, # [141]
  {
    amount           => "0.02344180", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108200000,    # .{3}
    gross_price_usd  => 7769.842,     # .{4}
    net_price_orig   => 108524600,    # .{5}
    net_price_usd    => 7793.151526,  # .{6}
  }, # [142]
  {
    amount           => "0.00020125",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108208000,     # .{3}
    gross_price_usd  => 7770.41648,    # .{4}
    net_price_orig   => 108532624,     # .{5}
    net_price_usd    => 7793.72772944, # .{6}
  }, # [143]
  {
    amount           => "0.00795553", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108210000,    # .{3}
    gross_price_usd  => 7770.5601,    # .{4}
    net_price_orig   => 108534630,    # .{5}
    net_price_usd    => 7793.8717803, # .{6}
  }, # [144]
  {
    amount           => "0.00240988",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108214000,     # .{3}
    gross_price_usd  => 7770.84734,    # .{4}
    net_price_orig   => 108538642,     # .{5}
    net_price_usd    => 7794.15988202, # .{6}
  }, # [145]
  {
    amount           => "0.00132283",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108219000,     # .{3}
    gross_price_usd  => 7771.20639,    # .{4}
    net_price_orig   => 108543657,     # .{5}
    net_price_usd    => 7794.52000917, # .{6}
  }, # [146]
  {
    amount           => "0.06173376",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108222000,     # .{3}
    gross_price_usd  => 7771.42182,    # .{4}
    net_price_orig   => 108546666,     # .{5}
    net_price_usd    => 7794.73608546, # .{6}
  }, # [147]
  {
    amount           => "0.00375366",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108233000,     # .{3}
    gross_price_usd  => 7772.21173,    # .{4}
    net_price_orig   => 108557699,     # .{5}
    net_price_usd    => 7795.52836519, # .{6}
  }, # [148]
  {
    amount           => "0.00277200", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108240000,    # .{3}
    gross_price_usd  => 7772.7144,    # .{4}
    net_price_orig   => 108564720,    # .{5}
    net_price_usd    => 7796.0325432, # .{6}
  }, # [149]
  {
    amount           => "0.00120000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108241000,     # .{3}
    gross_price_usd  => 7772.78621,    # .{4}
    net_price_orig   => 108565723,     # .{5}
    net_price_usd    => 7796.10456863, # .{6}
  }, # [150]
  {
    amount           => "0.00234526",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108245000,     # .{3}
    gross_price_usd  => 7773.07345,    # .{4}
    net_price_orig   => 108569735,     # .{5}
    net_price_usd    => 7796.39267035, # .{6}
  }, # [151]
  {
    amount           => "0.04843016", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108250000,    # .{3}
    gross_price_usd  => 7773.4325,    # .{4}
    net_price_orig   => 108574750,    # .{5}
    net_price_usd    => 7796.7527975, # .{6}
  }, # [152]
  {
    amount           => "0.00052979",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108253000,     # .{3}
    gross_price_usd  => 7773.64793,    # .{4}
    net_price_orig   => 108577759,     # .{5}
    net_price_usd    => 7796.96887379, # .{6}
  }, # [153]
  {
    amount           => "0.00886138",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108267000,     # .{3}
    gross_price_usd  => 7774.65327,    # .{4}
    net_price_orig   => 108591801,     # .{5}
    net_price_usd    => 7797.97722981, # .{6}
  }, # [154]
  {
    amount           => "0.00125004", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108270000,    # .{3}
    gross_price_usd  => 7774.8687,    # .{4}
    net_price_orig   => 108594810,    # .{5}
    net_price_usd    => 7798.1933061, # .{6}
  }, # [155]
  {
    amount           => "0.01890144",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108285000,     # .{3}
    gross_price_usd  => 7775.94585,    # .{4}
    net_price_orig   => 108609855,     # .{5}
    net_price_usd    => 7799.27368755, # .{6}
  }, # [156]
  {
    amount           => "0.00010000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108298000,     # .{3}
    gross_price_usd  => 7776.87938,    # .{4}
    net_price_orig   => 108622894,     # .{5}
    net_price_usd    => 7800.21001814, # .{6}
  }, # [157]
  {
    amount           => "0.02831039",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108299000,     # .{3}
    gross_price_usd  => 7776.95119,    # .{4}
    net_price_orig   => 108623897,     # .{5}
    net_price_usd    => 7800.28204357, # .{6}
  }, # [158]
  {
    amount           => "0.04930450", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108300000,    # .{3}
    gross_price_usd  => 7777.023,     # .{4}
    net_price_orig   => 108624900,    # .{5}
    net_price_usd    => 7800.354069,  # .{6}
  }, # [159]
  {
    amount           => "0.00101409",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108303000,     # .{3}
    gross_price_usd  => 7777.23843,    # .{4}
    net_price_orig   => 108627909,     # .{5}
    net_price_usd    => 7800.57014529, # .{6}
  }, # [160]
  {
    amount           => "0.13279375",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108304000,     # .{3}
    gross_price_usd  => 7777.31024,    # .{4}
    net_price_orig   => 108628912,     # .{5}
    net_price_usd    => 7800.64217072, # .{6}
  }, # [161]
  {
    amount           => "0.00513970",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108306000,     # .{3}
    gross_price_usd  => 7777.45386,    # .{4}
    net_price_orig   => 108630918,     # .{5}
    net_price_usd    => 7800.78622158, # .{6}
  }, # [162]
  {
    amount           => "0.02889901",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108317000,     # .{3}
    gross_price_usd  => 7778.24377,    # .{4}
    net_price_orig   => 108641951,     # .{5}
    net_price_usd    => 7801.57850131, # .{6}
  }, # [163]
  {
    amount           => "0.00865909",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108322000,     # .{3}
    gross_price_usd  => 7778.60282,    # .{4}
    net_price_orig   => 108646966,     # .{5}
    net_price_usd    => 7801.93862846, # .{6}
  }, # [164]
  {
    amount           => "0.00140000", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108330000,    # .{3}
    gross_price_usd  => 7779.1773,    # .{4}
    net_price_orig   => 108654990,    # .{5}
    net_price_usd    => 7802.5148319, # .{6}
  }, # [165]
  {
    amount           => "0.00046829",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108334000,     # .{3}
    gross_price_usd  => 7779.46454,    # .{4}
    net_price_orig   => 108659002,     # .{5}
    net_price_usd    => 7802.80293362, # .{6}
  }, # [166]
  {
    amount           => "0.00010000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108335000,     # .{3}
    gross_price_usd  => 7779.53635,    # .{4}
    net_price_orig   => 108660005,     # .{5}
    net_price_usd    => 7802.87495905, # .{6}
  }, # [167]
  {
    amount           => "0.00093411",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108343000,     # .{3}
    gross_price_usd  => 7780.11083,    # .{4}
    net_price_orig   => 108668029,     # .{5}
    net_price_usd    => 7803.45116249, # .{6}
  }, # [168]
  {
    amount           => "0.00096687",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108358000,     # .{3}
    gross_price_usd  => 7781.18798,    # .{4}
    net_price_orig   => 108683074,     # .{5}
    net_price_usd    => 7804.53154394, # .{6}
  }, # [169]
  {
    amount           => "0.00039504",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108367000,     # .{3}
    gross_price_usd  => 7781.83427,    # .{4}
    net_price_orig   => 108692101,     # .{5}
    net_price_usd    => 7805.17977281, # .{6}
  }, # [170]
  {
    amount           => "0.00398762",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108371000,     # .{3}
    gross_price_usd  => 7782.12151,    # .{4}
    net_price_orig   => 108696113,     # .{5}
    net_price_usd    => 7805.46787453, # .{6}
  }, # [171]
  {
    amount           => "0.00909022",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108378000,     # .{3}
    gross_price_usd  => 7782.62418,    # .{4}
    net_price_orig   => 108703134,     # .{5}
    net_price_usd    => 7805.97205254, # .{6}
  }, # [172]
  {
    amount           => "0.00058795",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108384000,     # .{3}
    gross_price_usd  => 7783.05504,    # .{4}
    net_price_orig   => 108709152,     # .{5}
    net_price_usd    => 7806.40420512, # .{6}
  }, # [173]
  {
    amount           => "0.00460475",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108385000,     # .{3}
    gross_price_usd  => 7783.12685,    # .{4}
    net_price_orig   => 108710155,     # .{5}
    net_price_usd    => 7806.47623055, # .{6}
  }, # [174]
  {
    amount           => "0.01129295",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108386000,     # .{3}
    gross_price_usd  => 7783.19866,    # .{4}
    net_price_orig   => 108711158,     # .{5}
    net_price_usd    => 7806.54825598, # .{6}
  }, # [175]
  {
    amount           => "0.00529111",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108387000,     # .{3}
    gross_price_usd  => 7783.27047,    # .{4}
    net_price_orig   => 108712161,     # .{5}
    net_price_usd    => 7806.62028141, # .{6}
  }, # [176]
  {
    amount           => "0.00510035",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108388000,     # .{3}
    gross_price_usd  => 7783.34228,    # .{4}
    net_price_orig   => 108713164,     # .{5}
    net_price_usd    => 7806.69230684, # .{6}
  }, # [177]
  {
    amount           => "0.00256441",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108398000,     # .{3}
    gross_price_usd  => 7784.06038,    # .{4}
    net_price_orig   => 108723194,     # .{5}
    net_price_usd    => 7807.41256114, # .{6}
  }, # [178]
  {
    amount           => "0.63846485", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108400000,    # .{3}
    gross_price_usd  => 7784.204,     # .{4}
    net_price_orig   => 108725200,    # .{5}
    net_price_usd    => 7807.556612,  # .{6}
  }, # [179]
  {
    amount           => "0.00109093",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108407000,     # .{3}
    gross_price_usd  => 7784.70667,    # .{4}
    net_price_orig   => 108732221,     # .{5}
    net_price_usd    => 7808.06079001, # .{6}
  }, # [180]
  {
    amount           => "0.01875822",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108428000,     # .{3}
    gross_price_usd  => 7786.21468,    # .{4}
    net_price_orig   => 108753284,     # .{5}
    net_price_usd    => 7809.57332404, # .{6}
  }, # [181]
  {
    amount           => "0.00688774", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108440000,    # .{3}
    gross_price_usd  => 7787.0764,    # .{4}
    net_price_orig   => 108765320,    # .{5}
    net_price_usd    => 7810.4376292, # .{6}
  }, # [182]
  {
    amount           => "0.00362718", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108450000,    # .{3}
    gross_price_usd  => 7787.7945,    # .{4}
    net_price_orig   => 108775350,    # .{5}
    net_price_usd    => 7811.1578835, # .{6}
  }, # [183]
  {
    amount           => "0.00290427",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108451000,     # .{3}
    gross_price_usd  => 7787.86631,    # .{4}
    net_price_orig   => 108776353,     # .{5}
    net_price_usd    => 7811.22990893, # .{6}
  }, # [184]
  {
    amount           => "0.10000000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108463000,     # .{3}
    gross_price_usd  => 7788.72803,    # .{4}
    net_price_orig   => 108788389,     # .{5}
    net_price_usd    => 7812.09421409, # .{6}
  }, # [185]
  {
    amount           => "0.00185413",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108467000,     # .{3}
    gross_price_usd  => 7789.01527,    # .{4}
    net_price_orig   => 108792401,     # .{5}
    net_price_usd    => 7812.38231581, # .{6}
  }, # [186]
  {
    amount           => "0.00053473",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108471000,     # .{3}
    gross_price_usd  => 7789.30251,    # .{4}
    net_price_orig   => 108796413,     # .{5}
    net_price_usd    => 7812.67041753, # .{6}
  }, # [187]
  {
    amount           => "0.00236038",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108472000,     # .{3}
    gross_price_usd  => 7789.37432,    # .{4}
    net_price_orig   => 108797416,     # .{5}
    net_price_usd    => 7812.74244296, # .{6}
  }, # [188]
  {
    amount           => "0.02129239",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108475000,     # .{3}
    gross_price_usd  => 7789.58975,    # .{4}
    net_price_orig   => 108800425,     # .{5}
    net_price_usd    => 7812.95851925, # .{6}
  }, # [189]
  {
    amount           => "0.00122800",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108476000,     # .{3}
    gross_price_usd  => 7789.66156,    # .{4}
    net_price_orig   => 108801428,     # .{5}
    net_price_usd    => 7813.03054468, # .{6}
  }, # [190]
  {
    amount           => "0.19325000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108479000,     # .{3}
    gross_price_usd  => 7789.87699,    # .{4}
    net_price_orig   => 108804437,     # .{5}
    net_price_usd    => 7813.24662097, # .{6}
  }, # [191]
  {
    amount           => "0.00248738",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108482000,     # .{3}
    gross_price_usd  => 7790.09242,    # .{4}
    net_price_orig   => 108807446,     # .{5}
    net_price_usd    => 7813.46269726, # .{6}
  }, # [192]
  {
    amount           => "0.00173565",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108484000,     # .{3}
    gross_price_usd  => 7790.23604,    # .{4}
    net_price_orig   => 108809452,     # .{5}
    net_price_usd    => 7813.60674812, # .{6}
  }, # [193]
  {
    amount           => "0.01200000",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108494000,     # .{3}
    gross_price_usd  => 7790.95414,    # .{4}
    net_price_orig   => 108819482,     # .{5}
    net_price_usd    => 7814.32700242, # .{6}
  }, # [194]
  {
    amount           => "0.00353581",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108499000,     # .{3}
    gross_price_usd  => 7791.31319,    # .{4}
    net_price_orig   => 108824497,     # .{5}
    net_price_usd    => 7814.68712957, # .{6}
  }, # [195]
  {
    amount           => "1.46748811", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108500000,    # .{3}
    gross_price_usd  => 7791.385,     # .{4}
    net_price_orig   => 108825500,    # .{5}
    net_price_usd    => 7814.759155,  # .{6}
  }, # [196]
  {
    amount           => "0.13047182",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108501000,     # .{3}
    gross_price_usd  => 7791.45681,    # .{4}
    net_price_orig   => 108826503,     # .{5}
    net_price_usd    => 7814.83118043, # .{6}
  }, # [197]
  {
    amount           => "0.41520960",  # .{0}
    currency         => "IDR",         # .{1}
    exchange         => "indodax",     # .{2}
    gross_price_orig => 108505000,     # .{3}
    gross_price_usd  => 7791.74405,    # .{4}
    net_price_orig   => 108830515,     # .{5}
    net_price_usd    => 7815.11928215, # .{6}
  }, # [198]
  {
    amount           => "0.05962323", # .{0}
    currency         => "IDR",        # .{1}
    exchange         => "indodax",    # .{2}
    gross_price_orig => 108510000,    # .{3}
    gross_price_usd  => 7792.1031,    # .{4}
    net_price_orig   => 108835530,    # .{5}
    net_price_usd    => 7815.4794093, # .{6}
  }, # [199]
];

my $all_buy_orders = [
    {
        amount           => 10,
        currency         => "USD",
        exchange         => "one",
        gross_price_orig => 101,
        gross_price_usd  => 101,
        net_price_orig   => 100,
        net_price_usd    => 100,
    },
    {
        amount           => 10,
        currency         => "USD",
        exchange         => "one",
        gross_price_orig => 100,
        gross_price_usd  => 100,
        net_price_orig   => 99,
        net_price_usd    => 99,
    },
];

my $all_sell_orders = [
    {
        amount           => 5,
        currency         => "USD",
        exchange         => "two",
        gross_price_orig => 100,
        gross_price_usd  => 100,
        net_price_orig   => 98,
        net_price_usd    => 98,
    },
    {
        amount           => 8,
        currency         => "USD",
        exchange         => "two",
        gross_price_orig => 100.5,
        gross_price_usd  => 100.5,
        net_price_orig   => 98.5,
        net_price_usd    => 98.5,
    },
];

my $order_pairs = App::cryp::arbit::Strategy::merge_order_book::_create_order_pairs(
    coin              => "BTC",
    all_buy_orders    => $all_buy_orders,
    all_sell_orders   => $all_sell_orders,
    min_profit_pct    => 1.0,
);

is_deeply($order_pairs, [
    {
        buy => {
            amount => "5",             # ..{0}
            exchange => "two",         # ..{1}
            gross_price_orig => "100", # ..{2}
            gross_price_usd => "100",  # ..{3}
            net_price_orig => "98",    # ..{4}
            net_price_usd => "98",     # ..{5}
            pair => "BTC/USD",         # ..{6}
        },                              # .{0}
        profit_pct => 2.04081632653061, # .{1}
        profit_usd => 10,               # .{2}
        sell => {
            amount => "5",             # ..{0}
            exchange => "one",         # ..{1}
            gross_price_orig => "101", # ..{2}
            gross_price_usd => "101",  # ..{3}
            net_price_orig => "100",   # ..{4}
            net_price_usd => "100",    # ..{5}
            pair => "BTC/USD",         # ..{6}
        },                              # .{3}
    }, # [0]
    {
        buy => {
            amount => "5",             # ..{0}
            exchange => "two",         # ..{1}
            gross_price_orig => 100.5, # ..{2}
            gross_price_usd => 100.5,  # ..{3}
            net_price_orig => 98.5,    # ..{4}
            net_price_usd => 98.5,     # ..{5}
            pair => "BTC/USD",         # ..{6}
        },                              # .{0}
        profit_pct => 1.52284263959391, # .{1}
        profit_usd => 7.5,              # .{2}
        sell => {
            amount => "5",             # ..{0}
            exchange => "one",         # ..{1}
            gross_price_orig => "101", # ..{2}
            gross_price_usd => "101",  # ..{3}
            net_price_orig => "100",   # ..{4}
            net_price_usd => "100",    # ..{5}
            pair => "BTC/USD",         # ..{6}
        },                              # .{3}
    }, # [1]
]) or diag explain $order_pairs;

is_deeply($all_buy_orders, [
    {
        amount           => "10",  # .{0}
        currency         => "USD", # .{1}
        exchange         => "one", # .{2}
        gross_price_orig => "100", # .{3}
        gross_price_usd  => "100", # .{4}
        net_price_orig   => "99",  # .{5}
        net_price_usd    => "99",  # .{6}
    }, # [0]
]) or diag exaplain $all_buy_orders;

is_deeply($all_sell_orders, [
    {
        amount           => "3",   # .{0}
        currency         => "USD", # .{1}
        exchange         => "two", # .{2}
        gross_price_orig => 100.5, # .{3}
        gross_price_usd  => 100.5, # .{4}
        net_price_orig   => 98.5,  # .{5}
        net_price_usd    => 98.5,  # .{6}
    }, # [0]
]) or diag explain $all_sell_orders;

done_testing;
