#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 & foo()
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_BIT_AND
right: !parsetree:FunctionCall
  arguments: ~
  context: CXT_SCALAR
  function: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
x &foo
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING|STRING_BARE
  value: x
op: OP_BIT_AND
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING|STRING_BARE
  value: foo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x;
x &foo
EOP
--- !parsetree:SubroutineDeclaration
name: x
--- !parsetree:FunctionCall
arguments:
  - !parsetree:SpecialFunctionCall
    arguments: ~
    context: CXT_LIST
    flags: FLAG_IMPLICITARGUMENTS
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo
      sigil: VALUE_SUB
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: VALUE_SUB
EOE
