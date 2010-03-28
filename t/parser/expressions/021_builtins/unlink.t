#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
unlink $a, @x
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  - !parsetree:Symbol
    context: CXT_LIST
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_UNLINK
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
unlink
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_UNLINK
EOE
