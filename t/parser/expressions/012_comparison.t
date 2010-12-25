#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a <=> $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_NUM_CMP
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a cmp $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_STR_CMP
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE
