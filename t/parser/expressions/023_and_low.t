#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print 1, 2 and die;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:BuiltinIndirect
  arguments:
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
  context: CXT_SCALAR
  function: OP_PRINT
  indirect: ~
op: OP_LOG_AND
right: !parsetree:Overridable
  arguments: ~
  context: CXT_VOID
  function: OP_DIE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1, 2, 3 and die
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:List
  context: CXT_SCALAR
  expressions:
    - !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
    - !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 3
op: OP_LOG_AND
right: !parsetree:Overridable
  arguments: ~
  context: CXT_VOID
  function: OP_DIE
EOE
