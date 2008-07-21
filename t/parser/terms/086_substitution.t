#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
s/foo/bar/g;
EOP
root:
    class: Language::P::ParseTree::Substitution
    pattern:
        class: Language::P::ParseTree::Pattern
        op: s
        components:
                class: Language::P::ParseTree::Constant
                value: foo
                type: string
        flags:
            g
    replacement:
        class: Language::P::ParseTree::Constant
        value: bar
        type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
s{foo}[$1];
EOP
root:
    class: Language::P::ParseTree::Substitution
    pattern:
        class: Language::P::ParseTree::Pattern
        op: s
        components:
                class: Language::P::ParseTree::Constant
                value: foo
                type: string
        flags: undef
    replacement:
        class: Language::P::ParseTree::QuotedString
        components:
                class: Language::P::ParseTree::Symbol
                name: 1
                sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
s{foo}'$1';
EOP
root:
    class: Language::P::ParseTree::Substitution
    pattern:
        class: Language::P::ParseTree::Pattern
        op: s
        components:
                class: Language::P::ParseTree::Constant
                value: foo
                type: string
        flags: undef
    replacement:
        class: Language::P::ParseTree::Constant
        value: $1
        type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
s/foo/my $x = 1; $x/ge;
EOP
root:
    class: Language::P::ParseTree::Substitution
    pattern:
        class: Language::P::ParseTree::Pattern
        op: s
        components:
                class: Language::P::ParseTree::Constant
                value: foo
                type: string
        flags:
            g
            e
    replacement:
        class: Language::P::ParseTree::Block
        lines:
                class: Language::P::ParseTree::BinOp
                op: =
                left:
                    class: Language::P::ParseTree::LexicalDeclaration
                    name: x
                    sigil: $
                    declaration_type: my
                right:
                    class: Language::P::ParseTree::Constant
                    value: 1
                    type: number
                class: Language::P::ParseTree::LexicalSymbol
                name: x
                sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
s/$foo/bar/g;
EOP
root:
    class: Language::P::ParseTree::Substitution
    pattern:
        class: Language::P::ParseTree::InterpolatedPattern
        op: s
        string:
            class: Language::P::ParseTree::QuotedString
            components:
                    class: Language::P::ParseTree::Symbol
                    name: foo
                    sigil: $
        flags:
            g
    replacement:
        class: Language::P::ParseTree::Constant
        value: bar
        type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
s'$foo'bar'g;
EOP
root:
    class: Language::P::ParseTree::Substitution
    pattern:
        class: Language::P::ParseTree::Pattern
        op: s
        components:
                class: Language::P::ParseTree::RXAssertion
                type: END_SPECIAL
                class: Language::P::ParseTree::Constant
                value: foo
                type: string
        flags:
            g
    replacement:
        class: Language::P::ParseTree::Constant
        value: bar
        type: string
EOE
