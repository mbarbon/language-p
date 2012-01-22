#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
exists $x{1}
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Subscript
    context: CXT_SCALAR|CXT_MAYBE_LVALUE
    reference: 0
    subscript: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: x
      sigil: VALUE_HASH
    type: VALUE_HASH
context: CXT_VOID
function: OP_EXISTS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
exists $x{1} + 1
EOP
--- !p:Exception
file: '<string>'
line: 1
message: exists argument is not a HASH or ARRAY element or a subroutine
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
exists &foo
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SUB
context: CXT_VOID
function: OP_EXISTS
EOE
