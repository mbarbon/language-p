#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 10;

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
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_LIST
    function: defined
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
function: print
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
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      - !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
    context: CXT_LIST
    function: unlink
context: CXT_VOID
function: print
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
      flags: CONST_STRING
      value: '>foo'
  context: CXT_SCALAR
  function: open
op: OP_LOG_OR
right: !parsetree:Overridable
  arguments:
    - !parsetree:Constant
      flags: CONST_STRING
      value: error
  context: CXT_VOID
  function: die
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
function: print
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: FILE
  sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE;
EOP
--- !parsetree:BuiltinIndirect
arguments: ~
context: CXT_VOID
function: print
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: FILE
  sigil: VALUE_GLOB
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
function: print
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
function: print
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
function: print
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE (), 1;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:List
    expressions: []
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: print
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
function: pipe
EOE
