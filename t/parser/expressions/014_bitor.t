#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a | $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_BIT_OR
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a ^ $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_BIT_XOR
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE
