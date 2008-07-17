#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff( <<'EOP', <<'EOE' );
@foo
EOP
root:
    class: Language::P::ParseTree::Symbol
    name: foo
    sigil: @
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$#foo
EOP
root:
    class: Language::P::ParseTree::Symbol
    name: foo
    sigil: $#
EOE

parse_and_diff( <<'EOP', <<'EOE' );
%foo
EOP
root:
    class: Language::P::ParseTree::Symbol
    name: foo
    sigil: %
EOE

parse_and_diff( <<'EOP', <<'EOE' );
*foo
EOP
root:
    class: Language::P::ParseTree::Symbol
    name: foo
    sigil: *
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$_
EOP
root:
    class: Language::P::ParseTree::Symbol
    name: _
    sigil: $
EOE

parse_and_diff( <<'EOP', <<'EOE' );
$#
EOP
root:
    class: Language::P::ParseTree::Symbol
    name: #
    sigil: $
EOE
