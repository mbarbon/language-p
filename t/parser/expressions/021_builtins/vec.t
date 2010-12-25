#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
vec( @a, 10, 4 )
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_ARRAY
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 10
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 4
context: CXT_VOID
function: OP_VEC
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
vec( $a, 10, 4 ) = 1
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Overridable
  arguments:
    - !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: a
      sigil: VALUE_SCALAR
    - !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 10
    - !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 4
  context: CXT_SCALAR|CXT_LVALUE
  function: OP_VEC
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE
