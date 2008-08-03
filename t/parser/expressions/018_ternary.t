#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
1 ? 2 : 3
EOP
root:
    class: Language::P::ParseTree::Ternary
    condition:
        class: Language::P::ParseTree::Number
        value: 1
        type: number
        flags: 1
    iftrue:
        class: Language::P::ParseTree::Number
        value: 2
        type: number
        flags: 1
    iffalse:
        class: Language::P::ParseTree::Number
        value: 3
        type: number
        flags: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$a = 1 ? 2 : 3
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: =
    left:
        class: Language::P::ParseTree::Symbol
        name: a
        sigil: $
    right:
        class: Language::P::ParseTree::Ternary
        condition:
            class: Language::P::ParseTree::Number
            value: 1
            type: number
            flags: 1
        iftrue:
            class: Language::P::ParseTree::Number
            value: 2
            type: number
            flags: 1
        iffalse:
            class: Language::P::ParseTree::Number
            value: 3
            type: number
            flags: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$a = 1 < 2 ? 2 + 3 : 3 + 4
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: =
    left:
        class: Language::P::ParseTree::Symbol
        name: a
        sigil: $
    right:
        class: Language::P::ParseTree::Ternary
        condition:
            class: Language::P::ParseTree::BinOp
            op: <
            left:
                class: Language::P::ParseTree::Number
                value: 1
                type: number
                flags: 1
            right:
                class: Language::P::ParseTree::Number
                value: 2
                type: number
                flags: 1
        iftrue:
            class: Language::P::ParseTree::BinOp
            op: +
            left:
                class: Language::P::ParseTree::Number
                value: 2
                type: number
                flags: 1
            right:
                class: Language::P::ParseTree::Number
                value: 3
                type: number
                flags: 1
        iffalse:
            class: Language::P::ParseTree::BinOp
            op: +
            left:
                class: Language::P::ParseTree::Number
                value: 3
                type: number
                flags: 1
            right:
                class: Language::P::ParseTree::Number
                value: 4
                type: number
                flags: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$x ? $a = 1 : $b = 2;
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: =
    left:
        class: Language::P::ParseTree::Ternary
        condition:
            class: Language::P::ParseTree::Symbol
            name: x
            sigil: $
        iftrue:
            class: Language::P::ParseTree::BinOp
            op: =
            left:
                class: Language::P::ParseTree::Symbol
                name: a
                sigil: $
            right:
                class: Language::P::ParseTree::Number
                value: 1
                type: number
                flags: 1
        iffalse:
            class: Language::P::ParseTree::Symbol
            name: b
            sigil: $
    right:
        class: Language::P::ParseTree::Number
        value: 2
        type: number
        flags: 1
EOE
