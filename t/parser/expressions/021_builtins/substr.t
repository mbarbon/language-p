#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
substr @a, @b, @c, @d
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
