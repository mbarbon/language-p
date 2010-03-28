#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
scalar @x
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SCALAR
EOE
