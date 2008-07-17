#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 12;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
$#[1]
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: #
        sigil: @
    subscript:
        class: Language::P::ParseTree::Constant
        value: 1
        type: number
    type: [
    reference: 0
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$_[1]
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: _
        sigil: @
    subscript:
        class: Language::P::ParseTree::Constant
        value: 1
        type: number
    type: [
    reference: 0
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$foo[1]
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: foo
        sigil: @
    subscript:
        class: Language::P::ParseTree::Constant
        value: 1
        type: number
    type: [
    reference: 0
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$foo{2}
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: foo
        sigil: %
    subscript:
        class: Language::P::ParseTree::Constant
        value: 2
        type: number
    type: {
    reference: 0
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$foo{2 + 3}
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: foo
        sigil: %
    subscript:
        class: Language::P::ParseTree::BinOp
        op: +
        left:
            class: Language::P::ParseTree::Constant
            value: 2
            type: number
        right:
            class: Language::P::ParseTree::Constant
            value: 3
            type: number
    type: {
    reference: 0
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$foo->()
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: foo
        sigil: $
    subscript: undef
    type: (
    reference: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$foo->( 1 + 2 )
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: foo
        sigil: $
    subscript:
        class: Language::P::ParseTree::BinOp
        op: +
        left:
            class: Language::P::ParseTree::Constant
            value: 1
            type: number
        right:
            class: Language::P::ParseTree::Constant
            value: 2
            type: number
    type: (
    reference: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
@foo[ 1, "xx", 3 + 4 ]
EOP
root:
    class: Language::P::ParseTree::Slice
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: foo
        sigil: @
    subscript:
        class: Language::P::ParseTree::List
        expressions:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
                class: Language::P::ParseTree::Constant
                value: xx
                type: string
                class: Language::P::ParseTree::BinOp
                op: +
                left:
                    class: Language::P::ParseTree::Constant
                    value: 3
                    type: number
                right:
                    class: Language::P::ParseTree::Constant
                    value: 4
                    type: number
    type: [
EOE

parse_and_diff( <<'EOP', <<'EOE' );
@foo{ 1, "xx", 3 + 4 }
EOP
root:
    class: Language::P::ParseTree::Slice
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: foo
        sigil: %
    subscript:
        class: Language::P::ParseTree::List
        expressions:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
                class: Language::P::ParseTree::Constant
                value: xx
                type: string
                class: Language::P::ParseTree::BinOp
                op: +
                left:
                    class: Language::P::ParseTree::Constant
                    value: 3
                    type: number
                right:
                    class: Language::P::ParseTree::Constant
                    value: 4
                    type: number
    type: {
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$foo[1]{2}->()[3]{5}( 1 + 2 + 3 );
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::Subscript
        subscripted:
            class: Language::P::ParseTree::Subscript
            subscripted:
                class: Language::P::ParseTree::Subscript
                subscripted:
                    class: Language::P::ParseTree::Subscript
                    subscripted:
                        class: Language::P::ParseTree::Subscript
                        subscripted:
                            class: Language::P::ParseTree::Symbol
                            name: foo
                            sigil: @
                        subscript:
                            class: Language::P::ParseTree::Constant
                            value: 1
                            type: number
                        type: [
                        reference: 0
                    subscript:
                        class: Language::P::ParseTree::Constant
                        value: 2
                        type: number
                    type: {
                    reference: 1
                subscript: undef
                type: (
                reference: 1
            subscript:
                class: Language::P::ParseTree::Constant
                value: 3
                type: number
            type: [
            reference: 1
        subscript:
            class: Language::P::ParseTree::Constant
            value: 5
            type: number
        type: {
        reference: 1
    subscript:
        class: Language::P::ParseTree::BinOp
        op: +
        left:
            class: Language::P::ParseTree::BinOp
            op: +
            left:
                class: Language::P::ParseTree::Constant
                value: 1
                type: number
            right:
                class: Language::P::ParseTree::Constant
                value: 2
                type: number
        right:
            class: Language::P::ParseTree::Constant
            value: 3
            type: number
    type: (
    reference: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
${foo}[1]
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::Symbol
        name: foo
        sigil: @
    subscript:
        class: Language::P::ParseTree::Constant
        value: 1
        type: number
    type: [
    reference: 0
EOE

parse_and_diff( <<'EOP', <<'EOE' );
${foo() . "x"}[1]
EOP
root:
    class: Language::P::ParseTree::Subscript
    subscripted:
        class: Language::P::ParseTree::UnOp
        op: $
        left:
            class: Language::P::ParseTree::Block
            lines:
                    class: Language::P::ParseTree::BinOp
                    op: .
                    left:
                        class: Language::P::ParseTree::FunctionCall
                        function: foo
                        arguments: undef
                    right:
                        class: Language::P::ParseTree::Constant
                        value: x
                        type: string
    subscript:
        class: Language::P::ParseTree::Constant
        value: 1
        type: number
    type: [
    reference: 0
EOE
