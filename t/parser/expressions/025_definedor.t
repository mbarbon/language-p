#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x // 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: VALUE_SCALAR
op: OP_DEFINED_OR
right: !parsetree:Constant
  context: CXT_VOID
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE
