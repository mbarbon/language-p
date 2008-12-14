#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print 1, 2 or die;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:BuiltinIndirect
  arguments:
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
  context: CXT_SCALAR
  function: OP_PRINT
  indirect: ~
op: OP_LOG_OR
right: !parsetree:Overridable
  arguments: ~
  context: CXT_VOID
  function: OP_DIE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1, 2, 3 or die
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:List
  expressions:
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 3
op: OP_LOG_OR
right: !parsetree:Overridable
  arguments: ~
  context: CXT_VOID
  function: OP_DIE
EOE
