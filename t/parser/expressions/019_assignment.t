#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x = 1;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: $
op: =
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x = 'test';
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: $
op: =
right: !parsetree:Constant
  type: string
  value: test
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@x = foo();
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_LIST|CXT_LVALUE
  name: x
  sigil: '@'
op: =
right: !parsetree:FunctionCall
  arguments: ~
  context: CXT_LIST
  function: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
( $x ) = foo();
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Parentheses
  context: CXT_LIST|CXT_LVALUE
  left: !parsetree:Symbol
    context: CXT_SCALAR|CXT_LVALUE
    name: x
    sigil: $
  op: ()
op: =
right: !parsetree:FunctionCall
  arguments: ~
  context: CXT_LIST
  function: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
( $x, $y ) = foo();
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:List
  expressions:
    - !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: x
      sigil: $
    - !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: y
      sigil: $
op: =
right: !parsetree:FunctionCall
  arguments: ~
  context: CXT_LIST
  function: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: '&'
EOE
