#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
map { foo() } 1, 2, 3
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  - !parsetree:Constant
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
map { foo() } 1, 2, 3
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  - !parsetree:Constant
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
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 3
context: CXT_VOID
function: OP_MAP
indirect: ~
EOE
