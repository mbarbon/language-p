#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 < 2
EOP
--- !parsetree:BinOp
left: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
op: <
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 > 2
EOP
--- !parsetree:BinOp
left: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
op: '>'
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 >= 2
EOP
--- !parsetree:BinOp
left: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
op: '>='
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 <= 2
EOP
--- !parsetree:BinOp
left: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
op: <=
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 2
EOE
