#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
{
    $x = 1;
    $y = 2
}
EOP
root:
    class: Language::P::ParseTree::Block
    lines:
            class: Language::P::ParseTree::BinOp
            op: =
            left:
                class: Language::P::ParseTree::Symbol
                name: x
                sigil: $
            right:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
            class: Language::P::ParseTree::BinOp
            op: =
            left:
                class: Language::P::ParseTree::Symbol
                name: y
                sigil: $
            right:
                class: Language::P::ParseTree::Constant
                value: 2
                type: number
EOE
