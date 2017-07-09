#!env perl

use strict;
use warnings FATAL => 'all';
use MarpaX::ESLIF::RFC3986;;
use Data::Dumper;

my ($input, $encoding) = @ARGV;

my $rfc3986 = MarpaX::ESLIF::RFC3986->new($input, $encoding);
print Dumper($rfc3986);

foreach ('is_absolute', 'base', MarpaX::ESLIF::RFC3986::ValueInterface->components) {
    printf "%s via self ==> %s\n", $_, $rfc3986->$_ // '<undef>';
    printf "%s via pkg  ==> %s\n", $_, MarpaX::ESLIF::RFC3986->$_($input, $encoding) // '<undef>';
}
