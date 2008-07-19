#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

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

parse_and_diff( <<'EOP', <<'EOE' );
sub x { };

x 1, 2;
EOP
root:
    class: Language::P::ParseTree::Subroutine
    name: x
    lines:
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
print, 1,
print, 1;
EOP
root:
    class: Language::P::ParseTree::List
    expressions:
            class: Language::P::ParseTree::Print
            function: print
            arguments: undef
            filehandle: undef
            class: Language::P::ParseTree::Constant
            value: 1
            type: number
            class: Language::P::ParseTree::Print
            function: print
            arguments: undef
            filehandle: undef
            class: Language::P::ParseTree::Constant
            value: 1
            type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
print, 1,
print => 1;
EOP
root:
    class: Language::P::ParseTree::List
    expressions:
            class: Language::P::ParseTree::Print
            function: print
            arguments: undef
            filehandle: undef
            class: Language::P::ParseTree::Constant
            value: 1
            type: number
            class: Language::P::ParseTree::Constant
            value: print
            type: string
            class: Language::P::ParseTree::Constant
            value: 1
            type: number
EOE
