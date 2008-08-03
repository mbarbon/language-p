#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
print defined 1, 2
EOP
root:
    class: Language::P::ParseTree::Print
    function: print
    arguments:
            class: Language::P::ParseTree::Builtin
            function: defined
            arguments:
                    class: Language::P::ParseTree::Number
                    value: 1
                    type: number
                    flags: 1
            class: Language::P::ParseTree::Number
            value: 2
            type: number
            flags: 1
    filehandle: undef
EOE

parse_and_diff( <<'EOP', <<'EOE' );
print unlink 1, 2
EOP
root:
    class: Language::P::ParseTree::Print
    function: print
    arguments:
            class: Language::P::ParseTree::Overridable
            function: unlink
            arguments:
                    class: Language::P::ParseTree::Number
                    value: 1
                    type: number
                    flags: 1
                    class: Language::P::ParseTree::Number
                    value: 2
                    type: number
                    flags: 1
    filehandle: undef
EOE

parse_and_diff( <<'EOP', <<'EOE' );
open FILE, ">foo" or die "error";
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: or
    left:
        class: Language::P::ParseTree::Overridable
        function: open
        arguments:
                class: Language::P::ParseTree::Symbol
                name: FILE
                sigil: *
                class: Language::P::ParseTree::Constant
                value: >foo
                type: string
    right:
        class: Language::P::ParseTree::Overridable
        function: die
        arguments:
                class: Language::P::ParseTree::Constant
                value: error
                type: string
EOE

parse_and_diff( <<'EOP', <<'EOE' );
print FILE $stuff;
EOP
root:
    class: Language::P::ParseTree::Print
    function: print
    arguments:
            class: Language::P::ParseTree::Symbol
            name: stuff
            sigil: $
    filehandle:
        class: Language::P::ParseTree::Symbol
        name: FILE
        sigil: *
EOE

parse_and_diff( <<'EOP', <<'EOE' );
pipe $foo, FILE
EOP
root:
    class: Language::P::ParseTree::Overridable
    function: pipe
    arguments:
            class: Language::P::ParseTree::Symbol
            name: foo
            sigil: $
            class: Language::P::ParseTree::Symbol
            name: FILE
            sigil: *
EOE
