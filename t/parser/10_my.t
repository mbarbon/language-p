#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
my $foo;
EOP
root:
    class: Language::P::ParseTree::LexicalDeclaration
    name: foo
    sigil: $
    declaration_type: my
EOE

parse_and_diff( <<'EOP', <<'EOE' );
my $foo = 1;
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: =
    left:
        class: Language::P::ParseTree::LexicalDeclaration
        name: foo
        sigil: $
        declaration_type: my
    right:
        class: Language::P::ParseTree::Constant
        value: 1
        type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
my( $foo, @bar ) = ( 1, 2, 3 );
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: =
    left:
        class: Language::P::ParseTree::List
        expressions:
                class: Language::P::ParseTree::LexicalDeclaration
                name: foo
                sigil: $
                declaration_type: my
                class: Language::P::ParseTree::LexicalDeclaration
                name: bar
                sigil: @
                declaration_type: my
    right:
        class: Language::P::ParseTree::List
        expressions:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
                class: Language::P::ParseTree::Constant
                value: 2
                type: number
                class: Language::P::ParseTree::Constant
                value: 3
                type: number
EOE
