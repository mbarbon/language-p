#!/usr/bin/perl -w

use t::lib::TestParser tests => 4;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
substr @a, @b, @c, @d
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR|CXT_LVALUE
    name: a
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: c
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: d
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SUBSTR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
substr @a, @b, @c
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: c
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SUBSTR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
substr @a, @b
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SUBSTR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
substr( $a, 1 ) = 1
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Overridable
  arguments:
    - !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: a
      sigil: VALUE_SCALAR
    - !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
  context: CXT_SCALAR|CXT_LVALUE
  function: OP_SUBSTR
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE
