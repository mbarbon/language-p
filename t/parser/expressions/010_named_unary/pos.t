#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
pos @x
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_POS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
pos
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_POS
EOE


parse_and_diff_yaml( <<'EOP', <<'EOE' );
pos( $a ) = 1
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Builtin
  arguments:
    - !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: a
      sigil: VALUE_SCALAR
  context: CXT_SCALAR|CXT_LVALUE
  function: OP_POS
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE
