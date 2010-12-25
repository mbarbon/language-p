#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x = $x .. $y
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_SCALAR
  op: OP_DOT_DOT
  right: !parsetree:Symbol
    context: CXT_SCALAR
    name: y
    sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x = $x ... $y
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_SCALAR
  op: OP_DOT_DOT_DOT
  right: !parsetree:Symbol
    context: CXT_SCALAR
    name: y
    sigil: VALUE_SCALAR
EOE
