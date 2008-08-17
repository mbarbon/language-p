#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
if( $a > 2 ) {
    1;
}
EOP
--- !parsetree:Conditional
iffalse: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
    block_type: if
    condition: !parsetree:BinOp
      context: CXT_SCALAR
      left: !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: $
      op: '>'
      right: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
unless( $a > 2 ) {
    1;
}
EOP
--- !parsetree:Conditional
iffalse: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
    block_type: unless
    condition: !parsetree:BinOp
      context: CXT_SCALAR
      left: !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: $
      op: '>'
      right: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
if( $a < 2 ) {
    1;
} else {
    3;
}
EOP
--- !parsetree:Conditional
iffalse: !parsetree:ConditionalBlock
  block: !parsetree:Block
    lines:
      - !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 3
  block_type: else
  condition: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
    block_type: if
    condition: !parsetree:BinOp
      context: CXT_SCALAR
      left: !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: $
      op: <
      right: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
if( $a < 2 ) {
    1;
} elsif( $a < 3 ) {
    2;
} else {
    3;
}
EOP
--- !parsetree:Conditional
iffalse: !parsetree:ConditionalBlock
  block: !parsetree:Block
    lines:
      - !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 3
  block_type: else
  condition: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
    block_type: if
    condition: !parsetree:BinOp
      context: CXT_SCALAR
      left: !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: $
      op: <
      right: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          flags: CONST_NUMBER|NUM_INTEGER
          value: 2
    block_type: if
    condition: !parsetree:BinOp
      context: CXT_SCALAR
      left: !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: $
      op: <
      right: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 3
EOE
