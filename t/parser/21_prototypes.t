#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
print defined 1, 2
EOP
root:
    class: Language::P::ParseTree::Builtin
    function: print
    arguments:
            class: Language::P::ParseTree::Builtin
            function: defined
            arguments:
                    class: Language::P::ParseTree::Constant
                    value: 1
                    type: number
            class: Language::P::ParseTree::Constant
            value: 2
            type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
print unlink 1, 2
EOP
root:
    class: Language::P::ParseTree::Builtin
    function: print
    arguments:
            class: Language::P::ParseTree::Overridable
            function: unlink
            arguments:
                    class: Language::P::ParseTree::Constant
                    value: 1
                    type: number
                    class: Language::P::ParseTree::Constant
                    value: 2
                    type: number
EOE
