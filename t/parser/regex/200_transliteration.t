#!/usr/bin/perl -w

use t::lib::TestParser tests => 4;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
tr/\x01\017\n\c[\w/abcde/
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
    - "\x01"
    - "\x0f"
    - "\n"
    - "\e"
    - w
  replacement:
    - a
    - b
    - c
    - d
    - e
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
tr{}{}
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
  match: []
  replacement: []
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
tr{-A-Z}{a-z-}
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
    - -
    -
      - A
      - Z
  replacement:
    -
      - a
      - z
    - -
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
tr{A-X-Z}{}
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
    -
      - A
      - X
    - -
    - Z
  replacement: []
EOE
