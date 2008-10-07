#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
local $foo;
EOP
--- !parsetree:Local
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_VOID|CXT_LVALUE
  name: foo
  sigil: 1
op: OP_LOCAL
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
local $foo{x} = 1;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Local
  context: CXT_SCALAR|CXT_LVALUE
  left: !parsetree:Subscript
    context: CXT_SCALAR|CXT_LVALUE
    reference: 0
    subscript: !parsetree:Constant
      flags: CONST_STRING
      value: x
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: foo
      sigil: VALUE_HASH
    type: 3
  op: OP_LOCAL
op: OP_ASSIGN
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
local( $x, $y ) = ( 1, 2 );
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Local
  context: CXT_LIST|CXT_LVALUE
  left: !parsetree:List
    expressions:
      - !parsetree:Symbol
        context: CXT_SCALAR|CXT_LVALUE
        name: x
        sigil: VALUE_SCALAR
      - !parsetree:Symbol
        context: CXT_SCALAR|CXT_LVALUE
        name: y
        sigil: VALUE_SCALAR
  op: OP_LOCAL
op: OP_ASSIGN
right: !parsetree:List
  expressions:
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
EOE
