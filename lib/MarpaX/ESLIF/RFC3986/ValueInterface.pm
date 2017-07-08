use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::RFC3986::ValueInterface;

# ABSTRACT: MarpaX::ESLIF::RFC3986 Value Interface

# VERSION

# AUTHORITY

=head1 DESCRIPTION

MarpaX::ESLIF::RFC3986's Value Interface

=head1 SYNOPSIS

    use MarpaX::ESLIF::RFC3986::ValueInterface;

    my $valueInterface = MarpaX::ESLIF::RFC3986::ValueInterface->new();

=cut

# -----------
# Constructor
# -----------

=head1 SUBROUTINES/METHODS

=head2 new($class)

Instantiate a new value interface object.

=cut

sub new {
    my ($pkg, %options) = @_;

    bless { result => undef, work => {}, %options }, $pkg
}

# ----------------
# Required methods
# ----------------

=head2 Required methods

=head3 isWithHighRankOnly

Returns a true or a false value, indicating if valuation should use highest ranked rules or not, respectively. Default is a true value.

=cut

sub isWithHighRankOnly { 1 }  # When there is the rank adverb: highest ranks only ?

=head3 isWithOrderByRank

Returns a true or a false value, indicating if valuation should order by rule rank or not, respectively. Default is a true value.

=cut

sub isWithOrderByRank  { 1 }  # When there is the rank adverb: order by rank ?

=head3 isWithAmbiguous

Returns a true or a false value, indicating if valuation should allow ambiguous parse tree or not, respectively. Default is a false value.

=cut

sub isWithAmbiguous    { 1 }  # Allow ambiguous parse ?

=head3 isWithNull

Returns a true or a false value, indicating if valuation should allow a null parse tree or not, respectively. Default is a false value.

=cut

sub isWithNull         { 0 }  # Allow null parse ?

=head3 maxParses

Returns the number of maximum parse tree valuations. Default is unlimited (i.e. a false value).

=cut

sub maxParses          { 0 }  # Maximum number of parse tree values

=head3 getResult

Returns the current parse tree value.

=cut

sub getResult { $_[0]->{result} }

=head3 setResult

Sets the current parse tree value.

=cut

sub setResult { $_[0]->{result} = $_[1] }

=head1 SEE ALSO

L<MarpaX::ESLIF::RFC3986>

=cut

#
# Grammar actions
# ---------------
#
# ... Special actions so that setResult gets $self->{work}
#
sub reference { $_[0]->{work} }
#
# ... All other actions are just bookkeeping current concatenation into $self->{workwork}
#
our @_ACTIONS = (
                 'URI',
                 'query',
                 'fragment',
                 'hier_part',
                 'absolute',
                 'relative',
                 'part',
                 'scheme',
                 'authority',
                 'userinfo',
                 'host',
                 'port',
                 'path',
                 'IP_literal',
                 'IPv4address',
                 'IPv6address',
                 'IPv6addrz',
                 'IPvFuture',
                 'reg_name',
                 'zone',
                );
foreach my $action (@_ACTIONS) {
  my $stub = "sub $action {
                my \$self = shift;
                \$self->{work}->{'$action'} = join('', map { \$_ // '' } \@_)
              }";
  eval $stub
}

1;
