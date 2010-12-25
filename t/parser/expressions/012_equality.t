#!/usr/bin/perl -w

use t::lib::TestParser tests => 4;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a == $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_NUM_EQ
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a eq $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_STR_EQ
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a != $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_NUM_NE
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a ne $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_STR_NE
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE
