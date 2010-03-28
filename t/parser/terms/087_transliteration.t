#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
tr/ab/AB/
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Transliteration
  flags: 0
  match:
    - a
    - b
  replacement:
    - A
    - B
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
y/ab//d
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Transliteration
  flags: FLAG_RX_DELETE
  match:
    - a
    - b
  replacement: []
EOE
