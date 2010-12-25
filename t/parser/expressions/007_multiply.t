#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 * 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_MULTIPLY
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 / 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_DIVIDE
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 % 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_MODULUS
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE
