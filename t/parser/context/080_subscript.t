#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a[1] = 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Subscript
  context: CXT_SCALAR|CXT_LVALUE
  reference: 0
  subscript: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  subscripted: !parsetree:Symbol
    context: CXT_LIST|CXT_LVALUE
    name: a
    sigil: VALUE_ARRAY
  type: VALUE_ARRAY
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE
