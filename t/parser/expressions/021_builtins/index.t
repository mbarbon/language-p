#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
index @foo, @moo
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: moo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_INDEX
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
index @foo, @moo, @boo
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: moo
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: boo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_INDEX
EOE
