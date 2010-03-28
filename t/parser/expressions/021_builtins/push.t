#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
push @foo, 1, 2;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
function: OP_ARRAY_PUSH
EOE
