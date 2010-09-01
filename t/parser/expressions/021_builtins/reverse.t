#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
reverse @x
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_REVERSE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
reverse
EOP
--- !parsetree:Overridable
arguments: ~
context: CXT_VOID
function: OP_REVERSE
EOE
