#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
eval $foo;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_EVAL
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x = eval { 1 => 1 };
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:EvalBlock
  context: CXT_SCALAR
  lines:
    - !parsetree:List
      context: CXT_SCALAR
      expressions:
        - !parsetree:Constant
          context: CXT_VOID
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
        - !parsetree:Constant
          context: CXT_SCALAR
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
eval +{ 1 => 1 }
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:UnOp
    context: CXT_LIST
    left: !parsetree:ReferenceConstructor
      expression: !parsetree:List
        context: CXT_LIST
        expressions:
          - !parsetree:Constant
            context: CXT_LIST
            flags: CONST_NUMBER|NUM_INTEGER
            value: 1
          - !parsetree:Constant
            context: CXT_LIST
            flags: CONST_NUMBER|NUM_INTEGER
            value: 1
      type: VALUE_HASH
    op: OP_PLUS
context: CXT_VOID
function: OP_EVAL
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
eval( { 1 => 1 } )
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:ReferenceConstructor
    expression: !parsetree:List
      context: CXT_LIST
      expressions:
        - !parsetree:Constant
          context: CXT_LIST
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
        - !parsetree:Constant
          context: CXT_LIST
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
    type: VALUE_HASH
context: CXT_VOID
function: OP_EVAL
EOE
