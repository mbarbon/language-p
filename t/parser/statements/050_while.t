#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
while( $a > 2 ) {
    1;
}
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:Block
  lines:
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
block_type: while
condition: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  op: OP_NUM_GT
  right: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
until( $a < 2 ) {
    1;
}
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:Block
  lines:
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
block_type: until
condition: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  op: OP_NUM_LT
  right: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
EOE
