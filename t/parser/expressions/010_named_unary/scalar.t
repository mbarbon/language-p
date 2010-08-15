#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
scalar @x
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
scalar 1, 2, 3
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:Builtin
    arguments:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_VOID
    function: OP_SCALAR
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 3
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
scalar( 1, 2, 3 )
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:List
    context: CXT_SCALAR
    expressions:
      - !parsetree:Constant
        context: CXT_VOID
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      - !parsetree:Constant
        context: CXT_VOID
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 3
context: CXT_VOID
function: OP_SCALAR
EOE
