#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
if( $a > 2 ) {
    1;
}
EOP
root:
    class: Language::P::ParseTree::Conditional
    iftrues:
            if
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
                class: Language::P::ParseTree::Block
                lines:
                        class: Language::P::ParseTree::Constant
                        value: 1
                        type: number
    iffalse: undef
EOE

parse_and_diff( <<'EOP', <<'EOE' );
unless( $a > 2 ) {
    1;
}
EOP
root:
    class: Language::P::ParseTree::Conditional
    iftrues:
            unless
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
                class: Language::P::ParseTree::Block
                lines:
                        class: Language::P::ParseTree::Constant
                        value: 1
                        type: number
    iffalse: undef
EOE

parse_and_diff( <<'EOP', <<'EOE' );
if( $a < 2 ) {
    1;
} else {
    3;
}
EOP
root:
    class: Language::P::ParseTree::Conditional
    iftrues:
            if
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
                class: Language::P::ParseTree::Block
                lines:
                        class: Language::P::ParseTree::Constant
                        value: 1
                        type: number
    iffalse:
        else
        undef
            class: Language::P::ParseTree::Block
            lines:
                    class: Language::P::ParseTree::Constant
                    value: 3
                    type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
if( $a < 2 ) {
    1;
} elsif( $a < 3 ) {
    2;
} else {
    3;
}
EOP
root:
    class: Language::P::ParseTree::Conditional
    iftrues:
            if
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
                class: Language::P::ParseTree::Block
                lines:
                        class: Language::P::ParseTree::Constant
                        value: 1
                        type: number
            if
                class: Language::P::ParseTree::BinOp
                op: <
                left:
                    class: Language::P::ParseTree::Symbol
                    name: a
                    sigil: $
                right:
                    class: Language::P::ParseTree::Constant
                    value: 3
                    type: number
                class: Language::P::ParseTree::Block
                lines:
                        class: Language::P::ParseTree::Constant
                        value: 2
                        type: number
    iffalse:
        else
        undef
            class: Language::P::ParseTree::Block
            lines:
                    class: Language::P::ParseTree::Constant
                    value: 3
                    type: number
EOE
