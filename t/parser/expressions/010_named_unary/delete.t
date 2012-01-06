#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
delete $x{1}
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Subscript
    context: CXT_SCALAR|CXT_NOCREATE
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
function: OP_DELETE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
delete $x[1]
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Subscript
    context: CXT_SCALAR|CXT_NOCREATE
    reference: 0
    subscript: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: x
      sigil: VALUE_ARRAY
    type: VALUE_ARRAY
context: CXT_VOID
function: OP_DELETE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
delete @x{1}
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Slice
    context: CXT_SCALAR
    reference: 0
    subscript: !parsetree:List
      context: CXT_LIST
      expressions:
        - !parsetree:Constant
          context: CXT_LIST
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: x
      sigil: VALUE_HASH
    type: VALUE_HASH
context: CXT_VOID
function: OP_DELETE
EOE
