#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
splice @x, @y, @z, $x, $y
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: x
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: y
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: z
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_SCALAR
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: y
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_SPLICE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
splice @x
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SPLICE
EOE
