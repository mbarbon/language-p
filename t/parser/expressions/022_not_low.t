#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
not $a + $b
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  op: OP_ADD
  right: !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: VALUE_SCALAR
op: OP_LOG_NOT
EOE
