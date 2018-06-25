package App::cryp::arbit::Strategy::null;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

with 'App::cryp::Role::ArbitStrategy';

sub calculate_order_pairs {
    my ($pkg, %args) = @_;

    return [200, "OK", []];
}

1;
# ABSTRACT: Do nothing (for testing)

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

=head1 DESCRIPTION

This strategy does nothing and will always return empty order pairs. For testing
only.
