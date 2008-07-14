#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
print 1, 2 or die;
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: or
    left:
        class: Language::P::ParseTree::Builtin
        function: print
        arguments:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
                class: Language::P::ParseTree::Constant
                value: 2
                type: number
    right:
        class: Language::P::ParseTree::FunctionCall
        function: die
        arguments: undef
EOE
