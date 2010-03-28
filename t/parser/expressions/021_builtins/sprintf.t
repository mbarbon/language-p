#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sprintf @x, @y
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_LIST
    name: y
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SPRINTF
EOE
