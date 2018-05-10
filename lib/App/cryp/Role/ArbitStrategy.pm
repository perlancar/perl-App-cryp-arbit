package App::cryp::Role::ArbitStrategy;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny;

requires qw(
               create_order_pairs
       );

1;
# ABSTRACT: Role for arbitration strategy module

=head1 DESCRIPTION

An arbitration strategy module is picked by the main arbit module
(L<App::cryp::arbit>). It must supply a C<create_order_pairs> class method. This
class method is given some arguments (see L</"create_order_pairs"> for more
details), and then must return order pairs. The order pairs will be submitted to
the exchanges by the main arbit module.


=head1 REQUIRED METHODS

=head2 create_order_pairs

Usage:

 __PACKAGE__->create_order_pairs(%args) => [$status, $reason, $payload, \%resmeta]

Will be fed these arguments:

=over

=item * dbh

Database handle.

=item * clients

Hash. Exchange API client objects. Keys are exchange shortnames. Values are
objects. All clients should follow the L<App::cryp::Role::Exchange> role.

=item * balances

Hash. Keys are exchange shortnames, values are account balances. Each balance is
a hash with this structure:

 {
   $currency1 => $balance1, # e.g. "BTC" => 1.2345
   $currency2 => $balance2, $ e.g. "USD" => 2304.22
 }

=back

Must return an enveloped result. Its payload, upon success, is an array of
"order pairs".


=head1 INTERNAL NOTES

For ease of testing, all the required information should be passed as arguments
instead of having to be retrieved from the database.


=head1 SEE ALSO

L<App::cryp::arbit>

C<App::cryp::arbit::Strategy::*> modules.
