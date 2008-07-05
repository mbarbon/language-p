#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
"abcdefg";
EOP
root:
    class: Language::P::ParseTree::Constant
    value: abcdefg
    type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
"x\n";
EOP
root:
    class: Language::P::ParseTree::Constant
    value: x

    type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
"ab$a $b";
EOP
root:
    class: Language::P::ParseTree::QuotedString
    components:
            class: Language::P::ParseTree::Constant
            value: ab
            type: string
            class: Language::P::ParseTree::Symbol
            name: a
            sigil: $
            class: Language::P::ParseTree::Constant
            value:  
            type: string
            class: Language::P::ParseTree::Symbol
            name: b
            sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
"ab${a}cd";
EOP
root:
    class: Language::P::ParseTree::QuotedString
    components:
            class: Language::P::ParseTree::Constant
            value: ab
            type: string
            class: Language::P::ParseTree::Symbol
            name: a
            sigil: $
            class: Language::P::ParseTree::Constant
            value: cd
            type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$x = "1";
$x = 1;
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: =
    left:
        class: Language::P::ParseTree::Symbol
        name: x
        sigil: $
    right:
        class: Language::P::ParseTree::Constant
        value: 1
        type: string
root:
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
EOE
