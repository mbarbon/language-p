#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
return ( 1, 2, 3 )[2, 3];
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Slice
    context: CXT_CALLER
    reference: 0
    subscript: !parsetree:List
      context: CXT_LIST
      expressions:
        - !parsetree:Constant
          context: CXT_LIST
          flags: CONST_NUMBER|NUM_INTEGER
          value: 2
        - !parsetree:Constant
          context: CXT_LIST
          flags: CONST_NUMBER|NUM_INTEGER
          value: 3
    subscripted: !parsetree:List
      context: CXT_LIST
      expressions:
        - !parsetree:Constant
          context: CXT_LIST
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
        - !parsetree:Constant
          context: CXT_LIST
          flags: CONST_NUMBER|NUM_INTEGER
          value: 2
        - !parsetree:Constant
          context: CXT_LIST
          flags: CONST_NUMBER|NUM_INTEGER
          value: 3
    type: VALUE_LIST
context: CXT_CALLER
function: OP_RETURN
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
return 1, 2;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Constant
    context: CXT_CALLER
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    context: CXT_CALLER
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_CALLER
function: OP_RETURN
EOE
