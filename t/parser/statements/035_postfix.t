#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 while 1 < 2;
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
block_type: while
condition: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  op: OP_NUM_LT
  right: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
continue: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 + 1 until 1;
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:BinOp
  context: CXT_VOID
  left: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  op: OP_ADD
  right: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
block_type: until
condition: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
continue: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 + 1 if 1;
EOP
--- !parsetree:Conditional
iffalse: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:BinOp
      context: CXT_VOID
      left: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      op: OP_ADD
      right: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    block_type: if
    condition: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 + 1 unless 1;
EOP
--- !parsetree:Conditional
iffalse: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:BinOp
      context: CXT_VOID
      left: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      op: OP_ADD
      right: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    block_type: unless
    condition: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 for 1, 2;
EOP
--- !parsetree:Foreach
block: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
continue: ~
expression: !parsetree:List
  expressions:
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
variable: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
EOE
