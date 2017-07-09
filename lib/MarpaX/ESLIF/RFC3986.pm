use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::RFC3986;

# ABSTRACT: Uniform Resource Identifier (URI - RFC3986) using MarpaX::ESLIF

# AUTHORITY

# VERSION

use Carp qw/croak/;
use MarpaX::ESLIF::RFC3986::RecognizerInterface;
use MarpaX::ESLIF::RFC3986::ValueInterface;
use MarpaX::ESLIF;
use Scalar::Util qw/blessed/;

my $_ESLIF = MarpaX::ESLIF->new();
my @_START = ('URI reference', 'absolute URI');
my $_DATA  = do { local $/; <DATA> };

our %_BNF;
our %_G;
foreach my $start (@_START) {
    $_BNF{$start} = $_DATA;
    $_BNF{$start} =~ s/\$START/<$start>/;
    $_G{$start}   = MarpaX::ESLIF::Grammar->new($_ESLIF, $_BNF{$start});
}

sub new {
  my ($pkg, $input, $encoding) = @_;

  bless $pkg->decode($input, $encoding), $pkg
}

sub decode {
    my ($class, $input, $encoding) = @_;

    my $rc             = $class->_parseByStart($input, 'URI reference', $encoding, 0);
    $rc->{is_absolute} = $class->_parseByStart($input, 'absolute URI',  $encoding, 1);

    $rc
}

sub _parseByStart {
    my ($class, $input, $start, $encoding, $boolean) = @_;

    my $recognizerInterface = MarpaX::ESLIF::RFC3986::RecognizerInterface->new(data => $input, encoding => $encoding);
    my $valueInterface = MarpaX::ESLIF::RFC3986::ValueInterface->new();

    my $value = eval {
        $_G{$start}->parse($recognizerInterface, $valueInterface);
        $valueInterface->getResult
    };

    return $boolean ? ($value ? 1 : 0) : $value
}

sub _self {
    my ($pkg_or_self, $input, $encoding) = @_;

    ((blessed($pkg_or_self) // '') eq __PACKAGE__) ? $pkg_or_self : __PACKAGE__->new($input, $encoding);
}

sub base {
    my ($pkg_or_self, $input, $encoding) = @_;

    my $self = $pkg_or_self->_self($input, $encoding);
    #
    # Simply this is the reconstruction of
    # <absolute URI> ::= <scheme> ":" <hier part> <URI query>
    #
    # Do nothing if it is already absolute
    #
    if ($self->is_absolute) {
        #
        # So it matches: <URI reference> ::= <URI> | <relative ref>
        #
        return $self->URI // $self->relative_ref
    } else {
        croak 'Invalid URI' unless defined($self->{'scheme'});
        return $self->scheme . ':' . ($self->hier_part // '') . ($self->URI_query // '')
    }
}

#
# Accessor to all components supported + is_absolute
#
foreach my $component ('is_absolute', MarpaX::ESLIF::RFC3986::ValueInterface->components) {
    eval "sub $component {
            my (\$pkg_or_self, \$input, \$encoding) = \@_;

            my \$self = \$pkg_or_self->_self(\$input, \$encoding);
            return \$self->{$component}  # Okay it is autovivifies to undef
          }"
}

1;

__DATA__
:start ::= $START
#
# Reference: https://tools.ietf.org/html/rfc3986#appendix-A
# Reference: https://tools.ietf.org/html/rfc6874
#
<URI>                    ::= <scheme> ":" <hier part> <URI query> <URI fragment>             action => URI
<URI query>              ::= "?" <query>                                                     action => URI_query
<URI query>              ::=                                                                 action => URI_query
<URI fragment>           ::= "#" <fragment>                                                  action => URI_fragment
<URI fragment>           ::=                                                                 action => URI_fragment

<hier part>              ::= "//" <authority> <path abempty>                                 action => hier_part
                           | <path absolute>                                                 action => hier_part
                           | <path rootless>                                                 action => hier_part
                           | <path empty>                                                    action => hier_part

<URI reference>          ::= <URI>                                                           action => URI_reference
                           | <relative ref>                                                  action => URI_reference

<absolute URI>           ::= <scheme> ":" <hier part> <URI query>                            action => absolute_URI

<relative ref>           ::= <relative part> <URI query> <URI fragment>                      action => relative_ref

<relative part>          ::= "//" <authority> <path abempty>                                 action => relative_part
                           | <path absolute>                                                 action => relative_part
                           | <path noscheme>                                                 action => relative_part
                           | <path empty>                                                    action => relative_part

<scheme>                 ::= <ALPHA> <scheme trailer>                                        action => scheme
<scheme trailer unit>    ::= <ALPHA> | <DIGIT> | "+" | "-" | "."
<scheme trailer>         ::= <scheme trailer unit>*

<authority userinfo>     ::= <userinfo> "@"                                                  action => authority_userinfo
<authority userinfo>     ::=                                                                 action => authority_userinfo
<authority port>         ::= ":" <port>                                                      action => authority_port
<authority port>         ::=                                                                 action => authority_port
<authority>              ::= <authority userinfo> <host> <authority port>                    action => authority
<userinfo unit>          ::= <unreserved> | <pct encoded> | <sub delims> | ":"
<userinfo>               ::= <userinfo unit>*                                                action => userinfo
#
# The syntax rule for host is ambiguous because it does not completely
# distinguish between an IPv4address and a reg-name.  In order to
# disambiguate the syntax, we apply the "first-match-wins" algorithm:
# If host matches the rule for IPv4address, then it should be
# considered an IPv4 address literal and not a reg-name.
#
<host>                   ::= <IP literal>            rank =>  0                              action => host
                           | <IPv4address>           rank => -1                              action => host
                           | <reg name>              rank => -2                              action => host
<port>                   ::= <DIGIT>*                                                        action => port

<IP literal interior>    ::= <IPv6address> | <IPv6addrz> | <IPvFuture>
<IP literal>             ::= "[" <IP literal interior> "]"                                   action => IP_literal
<ZoneID interior>        ::= <unreserved>  | <pct encoded>
<ZoneID>                 ::= <ZoneID interior>+                                              action => ZoneID
<IPv6addrz>              ::= <IPv6address> "%25" <ZoneID>                        action => IPv6addrz

<IPvFuture>              ::= "v" <HEXDIG many> "." <IPvFuture trailer>                       action => IPvFuture
<IPvFuture trailer unit> ::= <unreserved> | <sub delims> | ":"
<IPvFuture trailer>      ::= <IPvFuture trailer unit>+

<IPv6address>            ::=                                   <6 h16 colon> <ls32>          action => IPv6address
                           |                              "::" <5 h16 colon> <ls32>          action => IPv6address
                           |                      <h16>   "::" <4 h16 colon> <ls32>          action => IPv6address
                           |                              "::" <4 h16 colon> <ls32>          action => IPv6address
                           |   <0 to 1 h16 colon> <h16>   "::" <3 h16 colon> <ls32>          action => IPv6address
                           |                              "::" <3 h16 colon> <ls32>          action => IPv6address
                           |   <0 to 2 h16 colon> <h16>   "::" <2 h16 colon> <ls32>          action => IPv6address
                           |                              "::" <2 h16 colon> <ls32>          action => IPv6address
                           |   <0 to 3 h16 colon> <h16>   "::" <1 h16 colon> <ls32>          action => IPv6address
                           |                              "::" <1 h16 colon> <ls32>          action => IPv6address
                           |   <0 to 4 h16 colon> <h16>   "::"               <ls32>          action => IPv6address
                           |                              "::"               <ls32>          action => IPv6address
                           |   <0 to 5 h16 colon> <h16>   "::"               <h16>           action => IPv6address
                           |                              "::"               <h16>           action => IPv6address
                           |   <0 to 6 h16 colon> <h16>   "::"                               action => IPv6address
                           |                              "::"                               action => IPv6address

<1 h16 colon>            ::= <h16> ":"
<2 h16 colon>            ::= <h16> ":" <h16> ":"
<3 h16 colon>            ::= <h16> ":" <h16> ":" <h16> ":"
<4 h16 colon>            ::= <h16> ":" <h16> ":" <h16> ":" <h16> ":"
<5 h16 colon>            ::= <h16> ":" <h16> ":" <h16> ":" <h16> ":" <h16> ":"
<6 h16 colon>            ::= <h16> ":" <h16> ":" <h16> ":" <h16> ":" <h16> ":" <h16> ":"

#
# These productions are ambiguous without ranking (rank is equivalent to make regexps greedy)
#
<0 to 1 h16 colon>       ::=
<0 to 1 h16 colon>       ::= <1 h16 colon>                    rank => 1
<0 to 2 h16 colon>       ::= <0 to 1 h16 colon>
<0 to 2 h16 colon>       ::= <0 to 1 h16 colon> <1 h16 colon> rank => 1
<0 to 3 h16 colon>       ::= <0 to 2 h16 colon>
<0 to 3 h16 colon>       ::= <0 to 2 h16 colon> <1 h16 colon> rank => 1
<0 to 4 h16 colon>       ::= <0 to 3 h16 colon>
<0 to 4 h16 colon>       ::= <0 to 3 h16 colon> <1 h16 colon> rank => 1
<0 to 5 h16 colon>       ::= <0 to 4 h16 colon>
<0 to 5 h16 colon>       ::= <0 to 4 h16 colon> <1 h16 colon> rank => 1
<0 to 6 h16 colon>       ::= <0 to 5 h16 colon>
<0 to 6 h16 colon>       ::= <0 to 5 h16 colon> <1 h16 colon> rank => 1

<h16>                    ::= <HEXDIG>
                           | <HEXDIG> <HEXDIG>
                           | <HEXDIG> <HEXDIG> <HEXDIG>
                           | <HEXDIG> <HEXDIG> <HEXDIG> <HEXDIG>

<ls32>                   ::= <h16> ":" <h16> | <IPv4address>
<IPv4address>            ::= <dec octet> "." <dec octet> "." <dec octet> "." <dec octet>   action => IPv4address

<dec octet>              ::= <DIGIT>                     # 0-9
                           | [\x{31}-\x{39}] <DIGIT>     # 10-99
                           | "1" <DIGIT> <DIGIT>         # 100-199
                           | "2" [\x{30}-\x{34}] <DIGIT> # 200-249
                           | "25" [\x{30}-\x{35}]        # 250-255

<reg name unit>          ::= <unreserved> | <pct encoded> | <sub delims>
<reg name>               ::= <reg name unit>*                                               action => reg_name

<path>                   ::= <path abempty>                                                 action => path # begins with "/" or is empty
                           | <path absolute>                                                action => path # begins with "/" but not "//"
                           | <path noscheme>                                                action => path # begins with a non-colon segment
                           | <path rootless>                                                action => path # begins with a segment
                           | <path empty>                                                   action => path # zero characters

<path abempty unit>      ::= "/" <segment>
<path abempty>           ::= <path abempty unit>*                                           action => path_abempty
<path absolute>          ::= "/"                                                            action => path_absolute
                           | "/" <segment nz> <path abempty>                                action => path_absolute
<path noscheme>          ::= <segment nz nc> <path abempty>                                 action => path_noscheme
<path rootless>          ::= <segment nz> <path abempty>                                    action => path_rootless
<path empty>             ::=                                                                action => path_empty

<segment>                ::= <pchar>*                                                       action => segment
<segment nz>             ::= <pchar>+                                                       action => segment_nz
<segment nz nc unit>     ::= <unreserved> | <pct encoded> | <sub delims> | "@" # non-zero-length segment without any colon ":"
<segment nz nc>          ::= <segment nz nc unit>+                                          action => segment_nz_nc

<pchar>                  ::= <unreserved> | <pct encoded> | <sub delims> | ":" | "@"

<query unit>             ::= <pchar> | "/" | "?"
<query>                  ::= <query unit>*                                                  action => query

<fragment unit>          ::= <pchar> | "/" | "?"
<fragment>               ::= <fragment unit>*                                               action => fragment

<pct encoded>            ::= "%" <HEXDIG> <HEXDIG>

<unreserved>             ::= <ALPHA> | <DIGIT> | "-" | "." | "_" | "~"
<reserved>               ::= <gen delims> | <sub delims>
<gen delims>             ::= ":" | "/" | "?" | "#" | "[" | "]" | "@"
<sub delims>             ::= "!" | "$" | "&" | "'" | "(" | ")"
                           | "*" | "+" | "," | ";" | "="

<HEXDIG many>            ::= <HEXDIG>+
<ALPHA>                  ::= [A-Za-z]
<DIGIT>                  ::= [0-9]
<HEXDIG>                 ::= [0-9A-Fa-f]          # case insensitive
