#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{
    $x = 1;
    $y = 2
}
EOP
--- !parsetree:Block
lines:
  - !parsetree:BinOp
    left: !parsetree:Symbol
      name: x
      sigil: $
    op: =
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
  - !parsetree:BinOp
    left: !parsetree:Symbol
      name: y
      sigil: $
    op: =
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 2
EOE
