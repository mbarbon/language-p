#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
undef @x
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_UNDEF
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
undef
EOP
--- !parsetree:Builtin
arguments: ~
context: CXT_VOID
function: OP_UNDEF
EOE
