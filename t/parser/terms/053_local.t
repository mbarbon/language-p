#!/usr/bin/perl -w

use t::lib::TestParser tests => 5;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
local $foo;
EOP
--- !parsetree:Local
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_VOID|CXT_LVALUE
  name: foo
  sigil: VALUE_SCALAR
op: OP_LOCAL
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
local( ${foo} );
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:Local
    context: CXT_VOID
    left: !parsetree:Symbol
      context: CXT_VOID|CXT_LVALUE
      name: foo
      sigil: VALUE_SCALAR
    op: OP_LOCAL
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
local $foo{x} = 1;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Local
  context: CXT_SCALAR|CXT_LVALUE
  left: !parsetree:Subscript
    context: CXT_SCALAR|CXT_LVALUE
    reference: 0
    subscript: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING
      value: x
    subscripted: !parsetree:Symbol
      context: CXT_LIST|CXT_LVALUE
      name: foo
      sigil: VALUE_HASH
    type: VALUE_HASH
  op: OP_LOCAL
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
local( $x, $y ) = ( 1, 2 );
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:List
  context: CXT_LIST|CXT_LVALUE
  expressions:
    - !parsetree:Local
      context: CXT_LIST|CXT_LVALUE
      left: !parsetree:Symbol
        context: CXT_SCALAR|CXT_LVALUE
        name: x
        sigil: VALUE_SCALAR
      op: OP_LOCAL
    - !parsetree:Local
      context: CXT_LIST|CXT_LVALUE
      left: !parsetree:Symbol
        context: CXT_SCALAR|CXT_LVALUE
        name: y
        sigil: VALUE_SCALAR
      op: OP_LOCAL
op: OP_ASSIGN
right: !parsetree:List
  context: CXT_LIST
  expressions:
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
local( $a ? $b : $c );
EOP
--- !parsetree:Ternary
condition: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
context: CXT_VOID
iffalse: !parsetree:Local
  context: CXT_VOID
  left: !parsetree:Symbol
    context: CXT_VOID|CXT_LVALUE
    name: c
    sigil: VALUE_SCALAR
  op: OP_LOCAL
iftrue: !parsetree:Local
  context: CXT_VOID
  left: !parsetree:Symbol
    context: CXT_VOID|CXT_LVALUE
    name: b
    sigil: VALUE_SCALAR
  op: OP_LOCAL
EOE
