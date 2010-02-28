#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
warn @foo
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_WARN
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
warn
EOP
--- !parsetree:Overridable
arguments: ~
context: CXT_VOID
function: OP_WARN
EOE
