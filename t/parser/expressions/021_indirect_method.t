#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

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
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 3
context: CXT_VOID
indirect: 0
invocant: !parsetree:Constant
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
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 3
  context: CXT_SCALAR
  indirect: 0
  invocant: !parsetree:Constant
    flags: CONST_STRING
    value: Foo
  method: foo
op: OP_LOG_OR
right: !parsetree:Overridable
  arguments: ~
  context: CXT_VOID
  function: die
EOE
