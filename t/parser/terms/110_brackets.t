#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 12;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$#[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: '#'
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$_[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: _
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo{2}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 2
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: '%'
type: '{'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo{2 + 3}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 2
  op: +
  right: !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 3
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: '%'
type: '{'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo->()
EOP
--- !parsetree:FunctionCall
arguments: ~
context: CXT_VOID
function: !parsetree:UnOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: $
  op: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo->( 1 + 2 )
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:BinOp
    context: CXT_LIST
    left: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
    op: +
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 2
context: CXT_VOID
function: !parsetree:UnOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: $
  op: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@foo[ 1, "xx", 3 + 4 ]
EOP
--- !parsetree:Slice
context: CXT_VOID
reference: 0
subscript: !parsetree:List
  expressions:
    - !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
    - !parsetree:Constant
      type: string
      value: xx
    - !parsetree:BinOp
      context: CXT_LIST
      left: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 3
      op: +
      right: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 4
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@foo{ 1, "xx", 3 + 4 }
EOP
--- !parsetree:Slice
context: CXT_VOID
reference: 0
subscript: !parsetree:List
  expressions:
    - !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
    - !parsetree:Constant
      type: string
      value: xx
    - !parsetree:BinOp
      context: CXT_LIST
      left: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 3
      op: +
      right: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 4
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: '%'
type: '{'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo[1]{2}->()[3]{5}( 1 + 2 + 3 );
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:BinOp
    context: CXT_LIST
    left: !parsetree:BinOp
      context: CXT_SCALAR
      left: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 1
      op: +
      right: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 2
    op: +
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 3
context: CXT_VOID
function: !parsetree:UnOp
  context: CXT_SCALAR
  left: !parsetree:Subscript
    context: CXT_SCALAR
    reference: 1
    subscript: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 5
    subscripted: !parsetree:Subscript
      context: CXT_SCALAR|CXT_LVALUE
      reference: 1
      subscript: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 3
      subscripted: !parsetree:FunctionCall
        arguments: ~
        context: CXT_SCALAR|CXT_LVALUE
        function: !parsetree:UnOp
          context: CXT_SCALAR
          left: !parsetree:Subscript
            context: CXT_SCALAR
            reference: 1
            subscript: !parsetree:Number
              flags: NUM_INTEGER
              type: number
              value: 2
            subscripted: !parsetree:Subscript
              context: CXT_SCALAR|CXT_LVALUE
              reference: 0
              subscript: !parsetree:Number
                flags: NUM_INTEGER
                type: number
                value: 1
              subscripted: !parsetree:Symbol
                context: CXT_LIST
                name: foo
                sigil: '@'
              type: '['
            type: '{'
          op: '&'
      type: '['
    type: '{'
  op: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${foo}[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${foo() . "x"}[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 1
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:UnOp
  context: CXT_SCALAR|CXT_LVALUE
  left: !parsetree:Block
    lines:
      - !parsetree:BinOp
        context: CXT_SCALAR
        left: !parsetree:FunctionCall
          arguments: ~
          context: CXT_SCALAR
          function: foo
        op: .
        right: !parsetree:Constant
          type: string
          value: x
  op: $
type: '['
EOE
