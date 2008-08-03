#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
BEGIN {
    1
}
EOP
root:
    class: Language::P::ParseTree::Subroutine
    name: BEGIN
    lines:
            class: Language::P::ParseTree::Number
            value: 1
            type: number
            flags: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
sub END {
    1
}
EOP
root:
    class: Language::P::ParseTree::Subroutine
    name: END
    lines:
            class: Language::P::ParseTree::Number
            value: 1
            type: number
            flags: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
END {
    1
}
EOP
root:
    class: Language::P::ParseTree::Subroutine
    name: END
    lines:
            class: Language::P::ParseTree::Number
            value: 1
            type: number
            flags: 1
EOE
