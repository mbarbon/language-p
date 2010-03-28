#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
uc @x
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_UC
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
uc
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_UC
EOE
