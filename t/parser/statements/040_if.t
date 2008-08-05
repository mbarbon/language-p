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
  -
    - if
    - !parsetree:BinOp
      left: !parsetree:Symbol
        name: a
        sigil: $
      op: '>'
      right: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 2
    - !parsetree:Block
      lines:
        - !parsetree:Number
          flags: NUM_INTEGER
          type: number
          value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
unless( $a > 2 ) {
    1;
}
EOP
--- !parsetree:Conditional
iffalse: ~
iftrues:
  -
    - unless
    - !parsetree:BinOp
      left: !parsetree:Symbol
        name: a
        sigil: $
      op: '>'
      right: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 2
    - !parsetree:Block
      lines:
        - !parsetree:Number
          flags: NUM_INTEGER
          type: number
          value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
if( $a < 2 ) {
    1;
} else {
    3;
}
EOP
--- !parsetree:Conditional
iffalse:
  - else
  - ~
  - !parsetree:Block
    lines:
      - !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 3
iftrues:
  -
    - if
    - !parsetree:BinOp
      left: !parsetree:Symbol
        name: a
        sigil: $
      op: <
      right: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 2
    - !parsetree:Block
      lines:
        - !parsetree:Number
          flags: NUM_INTEGER
          type: number
          value: 1
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
iffalse:
  - else
  - ~
  - !parsetree:Block
    lines:
      - !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 3
iftrues:
  -
    - if
    - !parsetree:BinOp
      left: !parsetree:Symbol
        name: a
        sigil: $
      op: <
      right: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 2
    - !parsetree:Block
      lines:
        - !parsetree:Number
          flags: NUM_INTEGER
          type: number
          value: 1
  -
    - if
    - !parsetree:BinOp
      left: !parsetree:Symbol
        name: a
        sigil: $
      op: <
      right: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 3
    - !parsetree:Block
      lines:
        - !parsetree:Number
          flags: NUM_INTEGER
          type: number
          value: 2
EOE
