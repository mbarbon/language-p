#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
foreach ( my $i = 0; $i < 10; $i = $i + 1 ) {
    1;
}
EOP
root:
    class: Language::P::ParseTree::For
    condition:
        class: Language::P::ParseTree::BinOp
        op: <
        left:
            class: Language::P::ParseTree::LexicalSymbol
            name: i
            sigil: $
        right:
            class: Language::P::ParseTree::Constant
            value: 10
            type: number
    block:
        class: Language::P::ParseTree::Block
        lines:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
    block_type: for
    initializer:
        class: Language::P::ParseTree::BinOp
        op: =
        left:
            class: Language::P::ParseTree::LexicalDeclaration
            name: i
            sigil: $
            declaration_type: my
        right:
            class: Language::P::ParseTree::Constant
            value: 0
            type: number
    step:
        class: Language::P::ParseTree::BinOp
        op: =
        left:
            class: Language::P::ParseTree::LexicalSymbol
            name: i
            sigil: $
        right:
            class: Language::P::ParseTree::BinOp
            op: +
            left:
                class: Language::P::ParseTree::LexicalSymbol
                name: i
                sigil: $
            right:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
foreach ( @a ) {
    1;
}
EOP
root:
    class: Language::P::ParseTree::Foreach
    expression:
        class: Language::P::ParseTree::Symbol
        name: a
        sigil: @
    block:
        class: Language::P::ParseTree::Block
        lines:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
    variable:
        class: Language::P::ParseTree::Symbol
        name: _
        sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
foreach $x ( @a ) {
    1;
}
EOP
root:
    class: Language::P::ParseTree::Foreach
    expression:
        class: Language::P::ParseTree::Symbol
        name: a
        sigil: @
    block:
        class: Language::P::ParseTree::Block
        lines:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
    variable:
        class: Language::P::ParseTree::Symbol
        name: x
        sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
foreach my $x ( @a ) {
    1;
}
EOP
root:
    class: Language::P::ParseTree::Foreach
    expression:
        class: Language::P::ParseTree::Symbol
        name: a
        sigil: @
    block:
        class: Language::P::ParseTree::Block
        lines:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
    variable:
        class: Language::P::ParseTree::LexicalDeclaration
        name: x
        sigil: $
        declaration_type: my
EOE
