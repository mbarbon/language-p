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
        class: Language::P::ParseTree::Print
        function: print
        arguments:
                class: Language::P::ParseTree::Number
                value: 1
                type: number
                flags: 1
                class: Language::P::ParseTree::Number
                value: 2
                type: number
                flags: 1
        filehandle: undef
    right:
        class: Language::P::ParseTree::Overridable
        function: die
        arguments: undef
EOE
