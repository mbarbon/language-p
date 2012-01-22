#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo( $a[1], $b{c} )
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Subscript
    context: CXT_LIST|CXT_MAYBE_LVALUE
    reference: 0
    subscript: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: a
      sigil: VALUE_ARRAY
    type: VALUE_ARRAY
  - !parsetree:Subscript
    context: CXT_LIST|CXT_MAYBE_LVALUE
    reference: 0
    subscript: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING
      value: c
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: b
      sigil: VALUE_HASH
    type: VALUE_HASH
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SUB
EOE
