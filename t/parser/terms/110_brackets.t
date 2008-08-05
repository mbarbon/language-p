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
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:Symbol
  name: '#'
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$_[1]
EOP
--- !parsetree:Subscript
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:Symbol
  name: _
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo[1]
EOP
--- !parsetree:Subscript
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:Symbol
  name: foo
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo{2}
EOP
--- !parsetree:Subscript
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 2
subscripted: !parsetree:Symbol
  name: foo
  sigil: '%'
type: '{'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo{2 + 3}
EOP
--- !parsetree:Subscript
reference: 0
subscript: !parsetree:BinOp
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
  name: foo
  sigil: '%'
type: '{'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo->()
EOP
--- !parsetree:FunctionCall
arguments: ~
function: !parsetree:UnOp
  left: !parsetree:Symbol
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
    left: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
    op: +
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 2
function: !parsetree:UnOp
  left: !parsetree:Symbol
    name: foo
    sigil: $
  op: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@foo[ 1, "xx", 3 + 4 ]
EOP
--- !parsetree:Slice
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
  name: foo
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@foo{ 1, "xx", 3 + 4 }
EOP
--- !parsetree:Slice
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
    left: !parsetree:BinOp
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
function: !parsetree:UnOp
  left: !parsetree:Subscript
    reference: 1
    subscript: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 5
    subscripted: !parsetree:Subscript
      reference: 1
      subscript: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 3
      subscripted: !parsetree:FunctionCall
        arguments: ~
        function: !parsetree:UnOp
          left: !parsetree:Subscript
            reference: 1
            subscript: !parsetree:Number
              flags: NUM_INTEGER
              type: number
              value: 2
            subscripted: !parsetree:Subscript
              reference: 0
              subscript: !parsetree:Number
                flags: NUM_INTEGER
                type: number
                value: 1
              subscripted: !parsetree:Symbol
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
reference: 0
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:Symbol
  name: foo
  sigil: '@'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${foo() . "x"}[1]
EOP
--- !parsetree:Subscript
reference: 1
subscript: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
subscripted: !parsetree:UnOp
  left: !parsetree:Block
    lines:
      - !parsetree:BinOp
        left: !parsetree:FunctionCall
          arguments: ~
          function: foo
        op: .
        right: !parsetree:Constant
          type: string
          value: x
  op: $
type: '['
EOE
