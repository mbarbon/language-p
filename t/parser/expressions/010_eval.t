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
function: eval
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
eval { 1 => 1 };
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Block
    lines:
      - !parsetree:List
        expressions:
          - !parsetree:Constant
            flags: CONST_NUMBER|NUM_INTEGER
            value: 1
          - !parsetree:Constant
            flags: CONST_NUMBER|NUM_INTEGER
            value: 1
context: CXT_VOID
function: eval
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
        expressions:
          - !parsetree:Constant
            flags: CONST_NUMBER|NUM_INTEGER
            value: 1
          - !parsetree:Constant
            flags: CONST_NUMBER|NUM_INTEGER
            value: 1
      type: VALUE_HASH
    op: OP_PLUS
context: CXT_VOID
function: eval
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
eval( { 1 => 1 } )
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:ReferenceConstructor
    expression: !parsetree:List
      expressions:
        - !parsetree:Constant
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
        - !parsetree:Constant
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
    type: VALUE_HASH
context: CXT_VOID
function: eval
EOE
