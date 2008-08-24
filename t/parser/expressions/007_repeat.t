#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1x2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_REPEAT
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x;
1 x 2
EOP
--- !parsetree:SubroutineDeclaration
name: x
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_REPEAT
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE
