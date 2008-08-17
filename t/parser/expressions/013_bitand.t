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
left: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
op: '&'
right: !parsetree:FunctionCall
  arguments: ~
  context: CXT_SCALAR
  function: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
x &foo
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Bareword
  type: string
  value: x
op: '&'
right: !parsetree:Bareword
  type: string
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
      sigil: '&'
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: '&'
EOE
