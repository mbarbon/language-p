#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
FOO: while(1) {
  last FOO;
}
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:Block
  lines:
    - !parsetree:Jump
      left: FOO
      op: OP_LAST
block_type: while
condition: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
continue: ~
label: FOO
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
FOO: while(1) {
  redo;
}
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:Block
  lines:
    - !parsetree:Jump
      left: ~
      op: OP_REDO
block_type: while
condition: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
continue: ~
label: FOO
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
last if 1;
EOP
--- !parsetree:Conditional
iffalse: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:Jump
      left: ~
      op: OP_LAST
    block_type: if
    condition: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
EOE
