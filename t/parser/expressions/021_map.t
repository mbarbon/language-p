#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
map { foo() } 1, 2, 3
EOP
--- !parsetree:BuiltinIndirect
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
function: OP_MAP
indirect: !parsetree:Block
  lines:
    - !parsetree:FunctionCall
      arguments: ~
      context: CXT_LIST
      function: !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
map { foo() } a()
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: VALUE_SUB
context: CXT_VOID
function: OP_MAP
indirect: !parsetree:Block
  lines:
    - !parsetree:FunctionCall
      arguments: ~
      context: CXT_LIST
      function: !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
map foo(), 1, 2, 3
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo
      sigil: VALUE_SUB
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
function: OP_MAP
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
map foo(), a()
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo
      sigil: VALUE_SUB
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: VALUE_SUB
context: CXT_VOID
function: OP_MAP
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
map $a->a || $b, 1
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:BinOp
    context: CXT_LIST
    left: !parsetree:MethodCall
      arguments: ~
      context: CXT_SCALAR
      indirect: 0
      invocant: !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: VALUE_SCALAR
      method: a
    op: OP_LOG_OR
    right: !parsetree:Symbol
      context: CXT_SCALAR
      name: b
      sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: OP_MAP
indirect: ~
EOE
