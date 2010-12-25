#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a = $b ** $c
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: a
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: VALUE_SCALAR
  op: OP_POWER
  right: !parsetree:Symbol
    context: CXT_SCALAR
    name: c
    sigil: VALUE_SCALAR
EOE
