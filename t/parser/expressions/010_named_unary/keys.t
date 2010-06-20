#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
keys %foo;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_HASH
context: CXT_VOID
function: OP_KEYS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
keys foo;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_HASH
context: CXT_VOID
function: OP_KEYS
EOE
