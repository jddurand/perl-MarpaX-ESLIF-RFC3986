use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::RFC3986;

# ABSTRACT: Uniform Resource Identifier (URI - RFC3986) using MarpaX::ESLIF

# AUTHORITY

# VERSION

use MarpaX::ESLIF::RFC3986::RecognizerInterface;
use MarpaX::ESLIF::RFC3986::ValueInterface;
use MarpaX::ESLIF;

use IO::Handle;
use Log::Log4perl qw/:easy/;
use Log::Any::Adapter;
use Log::Any qw/$log/;

autoflush STDOUT 1;
autoflush STDERR 1;

#
# Init log
#
our $defaultLog4perlConf = '
        log4perl.rootLogger              = TRACE, Screen
        log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
        log4perl.appender.Screen.stderr  = 0
        log4perl.appender.Screen.layout  = PatternLayout
        log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
        ';
Log::Log4perl::init(\$defaultLog4perlConf);
Log::Any::Adapter->set('Log4perl');

our $_BNF = do { local $/; <DATA> };
our $_ESLIF = MarpaX::ESLIF->new($log);
our $_G = MarpaX::ESLIF::Grammar->new($_ESLIF, $_BNF);

sub new {
  my ($pkg, $input, $encoding) = @_;

  bless _parse($input, $encoding), $pkg
}

sub _parse {
    my ($input, $encoding) = @_;

    my $recognizerInterface = MarpaX::ESLIF::RFC3986::RecognizerInterface->new(data => $input, encoding => $encoding);
    my $valueInterface = MarpaX::ESLIF::RFC3986::ValueInterface->new();

    if (0) {
        my $recognizer = MarpaX::ESLIF::Recognizer->new($_G, $recognizerInterface);
        $recognizer->scan();
        my $value = MarpaX::ESLIF::Value->new($recognizer, $valueInterface);
        my $i = 0;
        while ($value->value() > 0) {
            use Data::Dumper;
            print STDERR "VALUE No " . ++$i . ":\n" . Dumper($valueInterface->getResult);
        }
    }

    $_G->parse($recognizerInterface, $valueInterface);

    $valueInterface->getResult
}

1;

__DATA__
:start ::= <URI reference>
#
# Reference: https://tools.ietf.org/html/rfc3986#appendix-A
# Reference: https://tools.ietf.org/html/rfc6874
#
<URI>                    ::= <scheme> ":" <hier part> <URI query> <URI fragment>             action => URI
<URI query>              ::= "?" <query>                                                     action => query
<URI query>              ::=                                                                 action => query
<URI fragment>           ::= "#" <fragment>                                                  action => fragment
<URI fragment>           ::=                                                                 action => fragment

<hier part>              ::= "//" <authority> <path abempty>                                 action => hier_part
                           | <path absolute>                                                 action => hier_part
                           | <path rootless>                                                 action => hier_part
                           | <path empty>                                                    action => hier_part

<URI reference>          ::= <URI>                                                           action => reference
                           | <relative ref>                                                  action => reference

<absolute URI>           ::= <scheme> ":" <hier part> <URI query>                            action => absolute

<relative ref>           ::= <relative part> <URI query> <URI fragment>                      action => relative

<relative part>          ::= "//" <authority> <path abempty>                                 action => part
                           | <path absolute>                                                 action => part
                           | <path noscheme>                                                 action => part
                           | <path empty>                                                    action => part

<scheme>                 ::= <ALPHA> <scheme trailer>                                        action => scheme
<scheme trailer unit>    ::= <ALPHA> | <DIGIT> | "+" | "-" | "."
<scheme trailer>         ::= <scheme trailer unit>*

<authority userinfo>     ::= <userinfo> "@"
<authority userinfo>     ::=
<authority port>         ::= ":" <port>
<authority port>         ::=
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
<ZoneID>                 ::= <ZoneID interior>+                                              action => zone
<IPv6addrz>              ::= <IPv6address> "%25" <ZoneID>                                    action => IPv6addrz

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

<path>                   ::= <path abempty>              # begins with "/" or is empty
                           | <path absolute>             # begins with "/" but not "//"
                           | <path noscheme>             # begins with a non-colon segment
                           | <path rootless>             # begins with a segment
                           | <path empty>                # zero characters

<path abempty unit>      ::= "/" <segment>
<path abempty>           ::= <path abempty unit>*
<path absolute>          ::= "/"
<path absolute>          ::= "/" <segment nz> <path abempty>
<path noscheme>          ::= <segment nz nc> <path abempty>
<path rootless>          ::= <segment nz> <path abempty>
<path empty>             ::=

<segment>                ::= <pchar>*
<segment nz>             ::= <pchar>+
<segment nz nc unit>     ::= <unreserved> | <pct encoded> | <sub delims> | "@" # non-zero-length segment without any colon ":"
<segment nz nc>          ::= <segment nz nc unit>+

<pchar>                  ::= <unreserved> | <pct encoded> | <sub delims> | ":" | "@"

<query unit>             ::= <pchar> | "/" | "?"
<query>                  ::= <query unit>*

<fragment unit>          ::= <pchar> | "/" | "?"
<fragment>               ::= <fragment unit>*

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
