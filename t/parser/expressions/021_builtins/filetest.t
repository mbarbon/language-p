#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-t
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: STDIN
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_FT_ISTTY
EOE
