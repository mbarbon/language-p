#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 ? 2 : 3
EOP
--- !parsetree:Ternary
condition: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
iffalse: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 3
iftrue: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a = 1 ? 2 : 3
EOP
--- !parsetree:BinOp
left: !parsetree:Symbol
  name: a
  sigil: $
op: =
right: !parsetree:Ternary
  condition: !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 1
  iffalse: !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 3
  iftrue: !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a = 1 < 2 ? 2 + 3 : 3 + 4
EOP
--- !parsetree:BinOp
left: !parsetree:Symbol
  name: a
  sigil: $
op: =
right: !parsetree:Ternary
  condition: !parsetree:BinOp
    left: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
    op: <
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 2
  iffalse: !parsetree:BinOp
    left: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 3
    op: +
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 4
  iftrue: !parsetree:BinOp
    left: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 2
    op: +
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 3
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x ? $a = 1 : $b = 2;
EOP
--- !parsetree:BinOp
left: !parsetree:Ternary
  condition: !parsetree:Symbol
    name: x
    sigil: $
  iffalse: !parsetree:Symbol
    name: b
    sigil: $
  iftrue: !parsetree:BinOp
    left: !parsetree:Symbol
      name: a
      sigil: $
    op: =
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
op: =
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 2
EOE
