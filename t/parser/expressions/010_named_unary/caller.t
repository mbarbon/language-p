#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
caller @x
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_CALLER
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
caller
EOP
--- !parsetree:Overridable
arguments: ~
context: CXT_VOID
function: OP_CALLER
EOE
