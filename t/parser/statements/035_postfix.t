#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
1 while 1 < 2;
EOP
root:
    class: Language::P::ParseTree::ConditionalLoop
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
    block:
        class: Language::P::ParseTree::Number
        value: 1
        type: number
        flags: 1
    block_type: while
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1 + 1 until 1;
EOP
root:
    class: Language::P::ParseTree::ConditionalLoop
    condition:
        class: Language::P::ParseTree::Number
        value: 1
        type: number
        flags: 1
    block:
        class: Language::P::ParseTree::BinOp
        op: +
        left:
            class: Language::P::ParseTree::Number
            value: 1
            type: number
            flags: 1
        right:
            class: Language::P::ParseTree::Number
            value: 1
            type: number
            flags: 1
    block_type: until
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1 + 1 if 1;
EOP
root:
    class: Language::P::ParseTree::Conditional
    iftrues:
            if
                class: Language::P::ParseTree::Number
                value: 1
                type: number
                flags: 1
                class: Language::P::ParseTree::BinOp
                op: +
                left:
                    class: Language::P::ParseTree::Number
                    value: 1
                    type: number
                    flags: 1
                right:
                    class: Language::P::ParseTree::Number
                    value: 1
                    type: number
                    flags: 1
    iffalse: undef
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1 + 1 unless 1;
EOP
root:
    class: Language::P::ParseTree::Conditional
    iftrues:
            unless
                class: Language::P::ParseTree::Number
                value: 1
                type: number
                flags: 1
                class: Language::P::ParseTree::BinOp
                op: +
                left:
                    class: Language::P::ParseTree::Number
                    value: 1
                    type: number
                    flags: 1
                right:
                    class: Language::P::ParseTree::Number
                    value: 1
                    type: number
                    flags: 1
    iffalse: undef
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1 for 1, 2;
EOP
root:
    class: Language::P::ParseTree::Foreach
    expression:
        class: Language::P::ParseTree::List
        expressions:
                class: Language::P::ParseTree::Number
                value: 1
                type: number
                flags: 1
                class: Language::P::ParseTree::Number
                value: 2
                type: number
                flags: 1
    block:
        class: Language::P::ParseTree::Number
        value: 1
        type: number
        flags: 1
    variable:
        class: Language::P::ParseTree::Symbol
        name: _
        sigil: $
EOE
