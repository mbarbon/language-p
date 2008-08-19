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
    context: CXT_VOID
    left: !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: x
      sigil: VALUE_SCALAR
    op: OP_ASSIGN
    right: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
  - !parsetree:BinOp
    context: CXT_VOID
    left: !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: y
      sigil: VALUE_SCALAR
    op: OP_ASSIGN
    right: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
EOE
