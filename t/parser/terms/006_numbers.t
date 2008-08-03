#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 12;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
1725272
EOP
root:
    class: Language::P::ParseTree::Number
    value: 1725272
    type: number
    flags: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
0b101010
EOP
root:
    class: Language::P::ParseTree::Number
    value: 101010
    type: number
    flags: 17
EOE

parse_and_diff( <<'EOP', <<'EOE' );
0xffa1345
EOP
root:
    class: Language::P::ParseTree::Number
    value: ffa1345
    type: number
    flags: 5
EOE

parse_and_diff( <<'EOP', <<'EOE' );
0
EOP
root:
    class: Language::P::ParseTree::Number
    value: 0
    type: number
    flags: 1
EOE

parse_and_diff( <<'EOP', <<'EOE' );
0755
EOP
root:
    class: Language::P::ParseTree::Number
    value: 755
    type: number
    flags: 9
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1.2
EOP
root:
    class: Language::P::ParseTree::Number
    value: 1.2
    type: number
    flags: 2
EOE

parse_and_diff( <<'EOP', <<'EOE' );
173.
EOP
root:
    class: Language::P::ParseTree::Number
    value: 173
    type: number
    flags: 2
EOE

parse_and_diff( <<'EOP', <<'EOE' );
.0123
EOP
root:
    class: Language::P::ParseTree::Number
    value: 0.0123
    type: number
    flags: 2
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1E7
EOP
root:
    class: Language::P::ParseTree::Number
    value: 1e7
    type: number
    flags: 2
EOE

parse_and_diff( <<'EOP', <<'EOE' );
1e+07
EOP
root:
    class: Language::P::ParseTree::Number
    value: 1e+07
    type: number
    flags: 2
EOE

parse_and_diff( <<'EOP', <<'EOE' );
12.7e-3
EOP
root:
    class: Language::P::ParseTree::Number
    value: 12.7e-3
    type: number
    flags: 2
EOE

parse_and_diff( <<'EOP', <<'EOE' );
12..15
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: ..
    left:
        class: Language::P::ParseTree::Number
        value: 12
        type: number
        flags: 1
    right:
        class: Language::P::ParseTree::Number
        value: 15
        type: number
        flags: 1
EOE
