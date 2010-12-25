#!/usr/bin/perl -w

use t::lib::TestParser tests => 8;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 < 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_NUM_LT
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 lt 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_STR_LT
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 > 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_NUM_GT
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 gt 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_STR_GT
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 >= 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_NUM_GE
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 ge 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_STR_GE
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 <= 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_NUM_LE
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 le 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_STR_LE
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE
