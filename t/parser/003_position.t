#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 10;

use lib 't/lib';
use TestParser qw(:all);

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
