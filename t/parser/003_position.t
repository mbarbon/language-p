#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 12;
use Test::More import => [ qw(is is_deeply) ];

my $lexer = Language::P::Lexer->new( { string => <<EOP, file => 'a.pm' } );
print 7

+
8; foo();
#line 12 "moo.pm"
4
EOP

is( $lexer->lex->[0]->[0], 'a.pm' );
is( $lexer->lex->[0]->[1], 1 );

is( $lexer->lex->[0]->[1], 3 );

is( $lexer->lex->[0]->[1], 4 ) for 1 .. 6;

is_deeply( $lexer->lex->[0], ['moo.pm', 12] );

parse_and_diff_yaml( <<EOP, <<'EOE' );
 
        \xE2  
 
EOP
--- !p:Exception
file: '<string>'
line: 2
message: Unrecognized character \xE2 in column 9
EOE

parse_and_diff_yaml( <<EOP, <<'EOE' );
    
\xE2
     
EOP
--- !p:Exception
file: '<string>'
line: 2
message: Unrecognized character \xE2 in column 1
EOE
