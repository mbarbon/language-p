#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
pop foo;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_ARRAY_POP
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
pop
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: ARGV
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_ARRAY_POP
EOE
