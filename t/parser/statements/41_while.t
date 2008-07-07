#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
while( $a > 2 ) {
    1;
}
EOP
root:
    class: Language::P::ParseTree::ConditionalLoop
    condition:
        class: Language::P::ParseTree::BinOp
        op: >
        left:
            class: Language::P::ParseTree::Symbol
            name: a
            sigil: $
        right:
            class: Language::P::ParseTree::Constant
            value: 2
            type: number
    block:
        class: Language::P::ParseTree::Block
        lines:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
    block_type: while
EOE

parse_and_diff( <<'EOP', <<'EOE' );
until( $a < 2 ) {
    1;
}
EOP
root:
    class: Language::P::ParseTree::ConditionalLoop
    condition:
        class: Language::P::ParseTree::BinOp
        op: <
        left:
            class: Language::P::ParseTree::Symbol
            name: a
            sigil: $
        right:
            class: Language::P::ParseTree::Constant
            value: 2
            type: number
    block:
        class: Language::P::ParseTree::Block
        lines:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
    block_type: until
EOE
