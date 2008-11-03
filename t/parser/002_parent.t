#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

my $parser = fresh_parser();
$parser->parse_string( <<EOE, 'main' );
if( 1 ) {
    return 1;
}
EOE
my( $tree ) = @{parsed_program()};

is( $tree->parent, undef );
is( $tree->iftrues->[0]->parent, $tree );

is( $tree->iftrues->[0]->block->parent,
    $tree->iftrues->[0] );

is( $tree->iftrues->[0]->block->lines->[0]->parent,
    $tree->iftrues->[0]->block );

is( $tree->iftrues->[0]->block->lines->[0]->parent,
    $tree->iftrues->[0]->block );

is( $tree->iftrues->[0]->block->lines->[0]->arguments->[0]->parent,
    $tree->iftrues->[0]->block->lines->[0] );
