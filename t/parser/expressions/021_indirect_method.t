#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 19;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo Foo()
EOP
--- !parsetree:MethodCall
arguments: ~
context: CXT_VOID
indirect: 0
invocant: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: Foo
method: foo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo Foo 1, 2, 3
EOP
--- !parsetree:MethodCall
arguments:
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
context: CXT_VOID
indirect: 0
invocant: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: Foo
method: foo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo Foo 1, 2, 3 or die
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:MethodCall
  arguments:
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
  context: CXT_SCALAR
  indirect: 0
  invocant: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: Foo
  method: foo
op: OP_LOG_OR
right: !parsetree:Overridable
  arguments: ~
  context: CXT_VOID
  function: OP_DIE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print boo foo
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:MethodCall
    arguments: ~
    context: CXT_LIST
    indirect: 0
    invocant: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING
      value: foo
    method: boo
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print boo $foo
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: boo
  sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print map $foo, @foo
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:BuiltinIndirect
    arguments:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: VALUE_SCALAR
      - !parsetree:Symbol
        context: CXT_LIST
        name: foo
        sigil: VALUE_ARRAY
    context: CXT_LIST
    function: OP_MAP
    indirect: ~
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print foo + boo;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:UnOp
    context: CXT_LIST
    left: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING|STRING_BARE
      value: boo
    op: OP_PLUS
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo;
print foo + boo;
EOP
--- !parsetree:SubroutineDeclaration
name: foo
prototype: ~
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:FunctionCall
    arguments:
      - !parsetree:UnOp
        context: CXT_LIST
        left: !parsetree:Constant
          context: CXT_SCALAR
          flags: CONST_STRING|STRING_BARE
          value: boo
        op: OP_PLUS
    context: CXT_LIST
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo
      sigil: VALUE_SUB
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print foo . boo;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:BinOp
    context: CXT_LIST
    left: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING|STRING_BARE
      value: foo
    op: OP_CONCATENATE
    right: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING|STRING_BARE
      value: boo
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print moo()
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: moo
      sigil: VALUE_SUB
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print moo ()
EOP
--- !parsetree:BuiltinIndirect
arguments: []
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: moo
  sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
moo boo->foo
EOP
--- !parsetree:MethodCall
arguments: ~
context: CXT_VOID
indirect: 0
invocant: !parsetree:MethodCall
  arguments: ~
  context: CXT_SCALAR
  indirect: 0
  invocant: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: boo
  method: moo
method: foo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
meth $foo
EOP
--- !parsetree:MethodCall
arguments: ~
context: CXT_VOID
indirect: 0
invocant: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SCALAR
method: meth
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
meth $foo->{1}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 1
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
subscripted: !parsetree:MethodCall
  arguments: ~
  context: CXT_SCALAR|CXT_VIVIFY
  indirect: 0
  invocant: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
  method: meth
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
moo boo foo
EOP
--- !parsetree:MethodCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_STRING|STRING_BARE
    value: foo
context: CXT_VOID
indirect: 0
invocant: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: boo
method: moo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
meth {$foo{1}}
EOP
--- !parsetree:MethodCall
arguments: ~
context: CXT_VOID
indirect: 0
invocant: !parsetree:Block
  lines:
    - !parsetree:Subscript
      context: CXT_SCALAR
      reference: 0
      subscript: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      subscripted: !parsetree:Symbol
        context: CXT_LIST
        name: foo
        sigil: VALUE_HASH
      type: VALUE_HASH
method: meth
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
meth $foo{1}
EOP
--- !parsetree:MethodCall
arguments:
  - !parsetree:ReferenceConstructor
    expression: !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    type: VALUE_HASH
context: CXT_VOID
indirect: 0
invocant: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SCALAR
method: meth
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
meth $foo[1]
EOP
--- !parsetree:MethodCall
arguments:
  - !parsetree:ReferenceConstructor
    expression: !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    type: VALUE_ARRAY
context: CXT_VOID
indirect: 0
invocant: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SCALAR
method: meth
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
meth $foo({1})
EOP
--- !parsetree:MethodCall
arguments:
  - !parsetree:Parentheses
    context: CXT_LIST
    left: !parsetree:ReferenceConstructor
      expression: !parsetree:Constant
        context: CXT_LIST
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      type: VALUE_HASH
    op: OP_PARENTHESES
context: CXT_VOID
indirect: 0
invocant: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SCALAR
method: meth
EOE
