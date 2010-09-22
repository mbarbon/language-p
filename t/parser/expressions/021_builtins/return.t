#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

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

parse_and_diff_yaml( <<'EOP', <<'EOE' );
return ( shift )->{11} = 12;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:BinOp
    context: CXT_CALLER
    left: !parsetree:Subscript
      context: CXT_SCALAR|CXT_LVALUE
      reference: 1
      subscript: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 11
      subscripted: !parsetree:Parentheses
        context: CXT_SCALAR|CXT_VIVIFY
        left: !parsetree:Overridable
          arguments:
            - !parsetree:Symbol
              context: CXT_LIST
              name: ARGV
              sigil: VALUE_ARRAY
          context: CXT_SCALAR|CXT_VIVIFY
          function: OP_ARRAY_SHIFT
        op: OP_PARENTHESES
      type: VALUE_HASH
    op: OP_ASSIGN
    right: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 12
context: CXT_CALLER
function: OP_RETURN
EOE
