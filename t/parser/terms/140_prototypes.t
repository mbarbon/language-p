#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 17;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print defined 1, 2
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Builtin
    arguments:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_LIST
    function: OP_DEFINED
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print unlink 1, 2
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Overridable
    arguments:
      - !parsetree:Constant
        context: CXT_LIST
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      - !parsetree:Constant
        context: CXT_LIST
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
    context: CXT_LIST
    function: OP_UNLINK
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
open FILE, ">foo" or die "error";
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Overridable
  arguments:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: FILE
      sigil: VALUE_GLOB
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_STRING
      value: '>foo'
  context: CXT_SCALAR
  function: OP_OPEN
op: OP_LOG_OR
right: !parsetree:Overridable
  arguments:
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_STRING
      value: error
  context: CXT_VOID
  function: OP_DIE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE $stuff;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: stuff
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: FILE
  sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: FILE
  sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print {FILE};
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Block
  lines:
    - !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING|STRING_BARE
      value: FILE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print {$file[0]};
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Block
  lines:
    - !parsetree:Subscript
      context: CXT_SCALAR
      reference: 0
      subscript: !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_NUMBER|NUM_INTEGER
        value: 0
      subscripted: !parsetree:Symbol
        context: CXT_LIST
        name: file
        sigil: VALUE_ARRAY
      type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE +FOO;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:UnOp
    context: CXT_LIST
    left: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING|STRING_BARE
      value: FOO
    op: OP_PLUS
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: FILE
  sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE &FOO;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:SpecialFunctionCall
    arguments: ~
    context: CXT_LIST
    flags: FLAG_IMPLICITARGUMENTS
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: FOO
      sigil: VALUE_SUB
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: FILE
  sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE .FOO;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:BinOp
    context: CXT_LIST
    left: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING|STRING_BARE
      value: FILE
    op: OP_CONCATENATE
    right: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING|STRING_BARE
      value: FOO
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print $stuff + $b;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:BinOp
    context: CXT_LIST
    left: !parsetree:Symbol
      context: CXT_SCALAR
      name: stuff
      sigil: VALUE_SCALAR
    op: OP_ADD
    right: !parsetree:Symbol
      context: CXT_SCALAR
      name: b
      sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print $stuff;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: stuff
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE();
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: FILE
      sigil: VALUE_SUB
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE (), 1;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: OP_PRINT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: FILE
  sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
pipe $foo, FILE
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FILE
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_PIPE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print $foo $foo;
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
  name: foo
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print $foo{1}, 1;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Subscript
    context: CXT_LIST
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
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE
