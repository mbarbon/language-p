#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 6;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
[]
EOP
--- !parsetree:ReferenceConstructor
expression: !parsetree:List
  context: CXT_LIST
  expressions: []
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
[1]
EOP
--- !parsetree:ReferenceConstructor
expression: !parsetree:List
  context: CXT_LIST
  expressions:
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
[$a, 1 + 2]
EOP
--- !parsetree:ReferenceConstructor
expression: !parsetree:List
  context: CXT_LIST
  expressions:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: VALUE_SCALAR
    - !parsetree:BinOp
      context: CXT_LIST
      left: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      op: OP_ADD
      right: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{}
EOP
--- !parsetree:ReferenceConstructor
expression: !parsetree:List
  context: CXT_LIST
  expressions: []
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{q => 1}
EOP
--- !parsetree:ReferenceConstructor
expression: !parsetree:List
  context: CXT_LIST
  expressions:
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_STRING
      value: q
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{1}
EOP
--- !parsetree:BareBlock
continue: ~
lines:
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE
