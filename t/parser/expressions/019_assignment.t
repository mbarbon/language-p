#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x = 1;
EOP
--- !parsetree:BinOp
left: !parsetree:Symbol
  name: x
  sigil: $
op: =
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x = 'test';
EOP
--- !parsetree:BinOp
left: !parsetree:Symbol
  name: x
  sigil: $
op: =
right: !parsetree:Constant
  type: string
  value: test
EOE
