#!env perl

use strict;
use warnings FATAL => 'all';
use MarpaX::ESLIF::RFC3986;;
use Data::Dumper;

my ($input, $encoding) = @ARGV;

my $rfc3986 = MarpaX::ESLIF::RFC3986->new($input, $encoding);
print Dumper($rfc3986);

foreach ('scheme') {
    printf "==> %s = %s\n", $_, $rfc3986->$_ // '<undef>'
}
