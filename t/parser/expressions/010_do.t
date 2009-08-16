#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 9;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
do $foo;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_DO_FILE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
do $foo(1);
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: 2
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
do ${$foo}(1);
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: 2
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Dereference
    context: CXT_SCALAR
    left: !parsetree:Block
      lines:
        - !parsetree:Symbol
          context: CXT_SCALAR
          name: foo
          sigil: VALUE_SCALAR
    op: OP_DEREFERENCE_SCALAR
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
do foo(1);
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
do &$foo(1);
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:FunctionCall
    arguments:
      - !parsetree:Constant
        context: CXT_LIST
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_SCALAR
    function: !parsetree:Dereference
      context: CXT_SCALAR
      left: !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: VALUE_SCALAR
      op: OP_DEREFERENCE_SUB
context: CXT_VOID
function: OP_DO_FILE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
do die(1);
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Overridable
    arguments:
      - !parsetree:Constant
        context: CXT_LIST
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_SCALAR
    function: OP_DIE
context: CXT_VOID
function: OP_DO_FILE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
do { 1; 2 };
EOP
--- !parsetree:DoBlock
context: CXT_VOID
lines:
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x = do { 1; 2 };
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:DoBlock
  context: CXT_SCALAR
  lines:
    - !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo { do { 1; 2 } }
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:DoBlock
        context: CXT_CALLER
        lines:
          - !parsetree:Constant
            context: CXT_VOID
            flags: CONST_NUMBER|NUM_INTEGER
            value: 1
          - !parsetree:Constant
            context: CXT_CALLER
            flags: CONST_NUMBER|NUM_INTEGER
            value: 2
    context: CXT_CALLER
    function: OP_RETURN
name: foo
prototype: ~
EOE
