#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
die "Something wrong: ", $msg
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_STRING
    value: 'Something wrong: '
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: msg
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_DIE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
die
EOP
--- !parsetree:Overridable
arguments: ~
context: CXT_VOID
function: OP_DIE
EOE
