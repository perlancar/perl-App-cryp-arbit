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

=item * r

Hash. The Perinci::CmdLine request hash/stash, which contains many information
inside it, for example:

 $r->{_cryp}     # information from the configuration, e.g. exchanges, wallets, masternodes
 $r->{_stash}
   {dbh}
   ...

See L<App::cryp::arbit> for more details.


=head1 INTERNAL NOTES


=head1 SEE ALSO

L<App::cryp::arbit>

C<App::cryp::arbit::Strategy::*> modules.
