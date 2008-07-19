#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
+12
EOP
root:
    class: Language::P::ParseTree::Constant
    value: +12
    type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
-12
EOP
root:
    class: Language::P::ParseTree::Constant
    value: -12
    type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
-( 1 )
EOP
root:
    class: Language::P::ParseTree::UnOp
    op: -
    left:
        class: Language::P::ParseTree::Constant
        value: 1
        type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
-$x
EOP
root:
    class: Language::P::ParseTree::UnOp
    op: -
    left:
        class: Language::P::ParseTree::Symbol
        name: x
        sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
\1
EOP
root:
    class: Language::P::ParseTree::UnOp
    op: \
    left:
        class: Language::P::ParseTree::Constant
        value: 1
        type: number
EOE

parse_and_diff( <<'EOP', <<'EOE' );
\$a
EOP
root:
    class: Language::P::ParseTree::UnOp
    op: \
    left:
        class: Language::P::ParseTree::Symbol
        name: a
        sigil: $
EOE
