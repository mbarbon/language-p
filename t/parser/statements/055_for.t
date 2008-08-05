#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foreach ( my $i = 0; $i < 10; $i = $i + 1 ) {
    1;
}
EOP
--- !parsetree:For
block: !parsetree:Block
  lines:
    - !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
block_type: for
condition: !parsetree:BinOp
  left: !parsetree:LexicalSymbol
    name: i
    sigil: $
  op: <
  right: !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 10
initializer: !parsetree:BinOp
  left: !parsetree:LexicalDeclaration
    declaration_type: my
    name: i
    sigil: $
  op: =
  right: !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 0
step: !parsetree:BinOp
  left: !parsetree:LexicalSymbol
    name: i
    sigil: $
  op: =
  right: !parsetree:BinOp
    left: !parsetree:LexicalSymbol
      name: i
      sigil: $
    op: +
    right: !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foreach ( @a ) {
    1;
}
EOP
--- !parsetree:Foreach
block: !parsetree:Block
  lines:
    - !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
expression: !parsetree:Symbol
  name: a
  sigil: '@'
variable: !parsetree:Symbol
  name: _
  sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foreach $x ( @a ) {
    1;
}
EOP
--- !parsetree:Foreach
block: !parsetree:Block
  lines:
    - !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
expression: !parsetree:Symbol
  name: a
  sigil: '@'
variable: !parsetree:Symbol
  name: x
  sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foreach my $x ( @a ) {
    1;
}
EOP
--- !parsetree:Foreach
block: !parsetree:Block
  lines:
    - !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
expression: !parsetree:Symbol
  name: a
  sigil: '@'
variable: !parsetree:LexicalDeclaration
  declaration_type: my
  name: x
  sigil: $
EOE
