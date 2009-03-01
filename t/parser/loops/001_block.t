#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{
    $x = 1;
    $y = 2
}
EOP
--- !parsetree:BareBlock
continue: ~
lines:
  - !parsetree:BinOp
    context: CXT_VOID
    left: !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: x
      sigil: VALUE_SCALAR
    op: OP_ASSIGN
    right: !parsetree:Constant
      context: CXT_SCALAR
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
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{
    1;
} continue {
    2;
}
EOP
--- !parsetree:BareBlock
continue: !parsetree:Block
  lines:
    - !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
lines:
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE
