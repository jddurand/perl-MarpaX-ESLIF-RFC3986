use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::RFC3986::RecognizerInterface;

# ABSTRACT: MarpaX::ESLIF::RFC3986 Recognizer Interface

# VERSION

# AUTHORITY

=head1 DESCRIPTION

MarpaX::ESLIF::RFC3986's Recognizer Interface

=head1 SYNOPSIS

    use MarpaX::ESLIF::RFC3986::RecognizerInterface;

    my $recognizerInterface = MarpaX::ESLIF::RFC3986::RecognizerInterface->new();

=cut


# -----------
# Constructor
# -----------

=head1 SUBROUTINES/METHODS

=head2 new($class, $string, $encoding)

Instantiate a new recognizer interface object. Argument is the data, following eventually by encoding.

=cut

sub new {
    my ($pkg, %options) = @_;
    bless \%options, $pkg
}

# ----------------
# Required methods
# ----------------

=head2 Required methods

=head3 read($self)

Returns a true or a false value, indicating if last read was successful. Default is a true value.

=cut

sub read                   {        1 } # First read callback will be ok

=head3 isEof($self)

Returns a true or a false value, indicating if end-of-data is reached. Default is a true value.

=cut

sub isEof                  {        1 } # ../. and we will say this is EOF

=head3 isCharacterStream($self)

Returns a true or a false value, indicating if last read is a stream of characters. Default is a true value.

=cut

sub isCharacterStream      {        1 } # MarpaX::ESLIF will validate the input

=head3 encoding($self)

Returns encoding information. Default is undef.

=cut

sub encoding               { $_[0]->{encoding} } # Let MarpaX::ESLIF guess eventually

=head3 data($self)

Returns last bunch of data. Default is the string passed in the constructor.

=cut

sub data                   { $_[0]->{data} } # Data itself

=head3 isWithDisableThreshold($self)

Returns a true or a false value, indicating if threshold warning is on or off, respectively. Default is a false value.

=cut

sub isWithDisableThreshold {        0 } # Disable threshold warning ?

=head3 isWithExhaustion($self)

Returns a true or a false value, indicating if exhaustion event is on or off, respectively. Default is a false value.

=cut

sub isWithExhaustion       {        0 } # Exhaustion event ?

=head3 isWithNewline($self)

Returns a true or a false value, indicating if newline count is on or off, respectively. Default is a false value.

=cut

sub isWithNewline          {        0 } # Newline count ?

=head3 isWithTrack($self)

Returns a true or a false value, indicating if absolute position tracking is on or off, respectively. Default is a false value.

=cut

sub isWithTrack            {        1 } # Absolute position tracking ?

=head1 SEE ALSO

L<MarpaX::ESLIF::ECMA404>

=cut

1;
