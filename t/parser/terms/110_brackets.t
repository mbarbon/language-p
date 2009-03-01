#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 17;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$#[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: '#'
  sigil: VALUE_ARRAY
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$_[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: _
  sigil: VALUE_ARRAY
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: VALUE_ARRAY
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo{2}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: VALUE_HASH
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo{qq}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: qq
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: VALUE_HASH
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
*foo{HASH}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: HASH
subscripted: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_GLOB
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo{2 + 3}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  op: OP_ADD
  right: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 3
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: VALUE_HASH
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo->()
EOP
--- !parsetree:FunctionCall
arguments: ~
context: CXT_VOID
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo( 1 )->{2};
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 1
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
subscripted: !parsetree:FunctionCall
  arguments:
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
  context: CXT_SCALAR|CXT_VIVIFY
  function: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SUB
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo( 1 )->( 2 );
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:FunctionCall
    arguments:
      - !parsetree:Constant
        context: CXT_LIST
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_SCALAR
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo
      sigil: VALUE_SUB
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo->( 1 + 2 )
EOP
--- !parsetree:FunctionCall
arguments:
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
context: CXT_VOID
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@foo[ 1, "xx", 3 + 4 ]
EOP
--- !parsetree:Slice
context: CXT_VOID
reference: 0
subscript: !parsetree:List
  context: CXT_LIST
  expressions:
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_STRING
      value: xx
    - !parsetree:BinOp
      context: CXT_LIST
      left: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 3
      op: OP_ADD
      right: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 4
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: VALUE_ARRAY
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@foo{ 1, "xx", 3 + 4 }
EOP
--- !parsetree:Slice
context: CXT_VOID
reference: 0
subscript: !parsetree:List
  context: CXT_LIST
  expressions:
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_STRING
      value: xx
    - !parsetree:BinOp
      context: CXT_LIST
      left: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 3
      op: OP_ADD
      right: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 4
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: VALUE_HASH
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@{foo() . "x"}[1, 2, 3]
EOP
--- !parsetree:Slice
context: CXT_VOID
reference: 1
subscript: !parsetree:List
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
subscripted: !parsetree:Block
  lines:
    - !parsetree:BinOp
      context: CXT_SCALAR|CXT_VIVIFY
      left: !parsetree:FunctionCall
        arguments: ~
        context: CXT_SCALAR
        function: !parsetree:Symbol
          context: CXT_SCALAR
          name: foo
          sigil: VALUE_SUB
      op: OP_CONCATENATE
      right: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: x
type: VALUE_ARRAY
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
      left: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      op: OP_ADD
      right: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
    op: OP_ADD
    right: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 3
context: CXT_VOID
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Subscript
    context: CXT_SCALAR
    reference: 1
    subscript: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 5
    subscripted: !parsetree:Subscript
      context: CXT_SCALAR|CXT_VIVIFY
      reference: 1
      subscript: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 3
      subscripted: !parsetree:FunctionCall
        arguments: ~
        context: CXT_SCALAR|CXT_VIVIFY
        function: !parsetree:Dereference
          context: CXT_SCALAR
          left: !parsetree:Subscript
            context: CXT_SCALAR
            reference: 1
            subscript: !parsetree:Constant
              context: CXT_SCALAR
              flags: CONST_NUMBER|NUM_INTEGER
              value: 2
            subscripted: !parsetree:Subscript
              context: CXT_SCALAR|CXT_VIVIFY
              reference: 0
              subscript: !parsetree:Constant
                context: CXT_SCALAR
                flags: CONST_NUMBER|NUM_INTEGER
                value: 1
              subscripted: !parsetree:Symbol
                context: CXT_LIST
                name: foo
                sigil: VALUE_ARRAY
              type: VALUE_ARRAY
            type: VALUE_HASH
          op: OP_DEREFERENCE_SUB
      type: VALUE_ARRAY
    type: VALUE_HASH
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${foo}[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: VALUE_ARRAY
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${foo() . "x"}[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 1
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
subscripted: !parsetree:Block
  lines:
    - !parsetree:BinOp
      context: CXT_SCALAR|CXT_VIVIFY
      left: !parsetree:FunctionCall
        arguments: ~
        context: CXT_SCALAR
        function: !parsetree:Symbol
          context: CXT_SCALAR
          name: foo
          sigil: VALUE_SUB
      op: OP_CONCATENATE
      right: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: x
type: VALUE_ARRAY
EOE
