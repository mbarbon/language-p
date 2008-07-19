#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
moo.boo
EOP
root:
    class: Language::P::ParseTree::BinOp
    op: .
    left:
        class: Language::P::ParseTree::Bareword
        value: moo
        type: string
    right:
        class: Language::P::ParseTree::Bareword
        value: boo
        type: string
EOE
