#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
x( 1, 2 );
EOP
root:
    class: Language::P::ParseTree::FunctionCall
    function: x
    arguments:
            class: Language::P::ParseTree::Constant
            value: 1
            type: number
            class: Language::P::ParseTree::Constant
            value: 2
            type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
sub x;

x 1, 2;
EOP
root:
    class: Language::P::ParseTree::SubroutineDeclaration
    name: x
root:
    class: Language::P::ParseTree::FunctionCall
    function: x
    arguments:
            class: Language::P::ParseTree::Constant
            value: 1
            type: number
            class: Language::P::ParseTree::Constant
            value: 2
            type: number
EOE
