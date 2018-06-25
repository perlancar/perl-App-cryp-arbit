#!perl

use 5.010;
use strict;
use warnings;

use App::cryp::arbit;
use Test::More 0.98;
use Test::SQL::Schema::Versioned;
use Test::WithDB;

sql_schema_spec_ok(
    $App::cryp::arbit::db_schema_spec,
    Test::WithDB->new(
        config_profile => 'twdb-test-mysql',
    ),
);
done_testing;
