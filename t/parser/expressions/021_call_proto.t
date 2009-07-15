#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo();
foo + 1;
EOP
--- !parsetree:SubroutineDeclaration
name: foo
prototype:
  - 0
  - 0
  - 0
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:FunctionCall
  arguments: ~
  context: CXT_SCALAR
  function: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SUB
op: OP_ADD
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub mymap(&@);
mymap {1} 2, 3;
EOP
--- !parsetree:SubroutineDeclaration
name: mymap
prototype:
  - 1
  - -1
  - PROTO_SUB
  - PROTO_SUB
  - PROTO_ARRAY
--- !parsetree:FunctionCall
arguments:
  - !parsetree:AnonymousSubroutine
    lines:
      - !parsetree:Builtin
        arguments:
          - !parsetree:Constant
            context: CXT_CALLER
            flags: CONST_NUMBER|NUM_INTEGER
            value: 1
        context: CXT_CALLER
        function: OP_RETURN
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 3
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: mymap
  sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub mymap(&@);
mymap sub {1}, 2, 3;
EOP
--- !parsetree:SubroutineDeclaration
name: mymap
prototype:
  - 1
  - -1
  - PROTO_SUB
  - PROTO_SUB
  - PROTO_ARRAY
--- !parsetree:FunctionCall
arguments:
  - !parsetree:AnonymousSubroutine
    lines:
      - !parsetree:Builtin
        arguments:
          - !parsetree:Constant
            context: CXT_CALLER
            flags: CONST_NUMBER|NUM_INTEGER
            value: 1
        context: CXT_CALLER
        function: OP_RETURN
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 3
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: mymap
  sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub mymap(&@);
mymap {1}, 2, 3;
EOP
--- !parsetree:SubroutineDeclaration
name: mymap
prototype:
  - 1
  - -1
  - PROTO_SUB
  - PROTO_SUB
  - PROTO_ARRAY
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:FunctionCall
    arguments:
      - !parsetree:AnonymousSubroutine
        lines:
          - !parsetree:Builtin
            arguments:
              - !parsetree:Constant
                context: CXT_CALLER
                flags: CONST_NUMBER|NUM_INTEGER
                value: 1
            context: CXT_CALLER
            function: OP_RETURN
    context: CXT_VOID
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: mymap
      sigil: VALUE_SUB
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 3
EOE

# not really a prototype, but related
parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo;
foo->();
EOP
--- !parsetree:SubroutineDeclaration
name: foo
prototype: ~
--- !parsetree:FunctionCall
arguments: ~
context: CXT_VOID
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:FunctionCall
    arguments: ~
    context: CXT_SCALAR
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo
      sigil: VALUE_SUB
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo($$);
foo(@x, $y);
EOP
--- !parsetree:SubroutineDeclaration
name: foo
prototype:
  - 2
  - 2
  - 0
  - PROTO_SCALAR
  - PROTO_SCALAR
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: y
    sigil: VALUE_SCALAR
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SUB
EOE
