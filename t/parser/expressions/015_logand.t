#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@x && @y
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: VALUE_ARRAY
op: OP_LOG_AND
right: !parsetree:Symbol
  context: CXT_VOID
  name: y
  sigil: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@x && do { @y }
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: VALUE_ARRAY
op: OP_LOG_AND
right: !parsetree:DoBlock
  context: CXT_VOID
  lines:
    - !parsetree:Symbol
      context: CXT_VOID
      name: y
      sigil: VALUE_ARRAY
EOE
