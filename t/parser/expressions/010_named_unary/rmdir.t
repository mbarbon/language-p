#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
rmdir @foo
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_RMDIR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
rmdir
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_RMDIR
EOE
