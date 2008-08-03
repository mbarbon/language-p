#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
1 < 2
EOP
root:
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
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1 > 2
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: >
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
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1 >= 2
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: >=
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
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1 <= 2
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: <=
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
EOE
