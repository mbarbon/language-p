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
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
block_type: for
condition: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:LexicalSymbol
    context: CXT_SCALAR
    name: i
    sigil: $
  op: <
  right: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 10
initializer: !parsetree:BinOp
  context: CXT_VOID
  left: !parsetree:LexicalDeclaration
    context: CXT_SCALAR|CXT_LVALUE
    declaration_type: my
    name: i
    sigil: $
  op: =
  right: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 0
step: !parsetree:BinOp
  context: CXT_VOID
  left: !parsetree:LexicalSymbol
    context: CXT_SCALAR|CXT_LVALUE
    name: i
    sigil: $
  op: =
  right: !parsetree:BinOp
    context: CXT_SCALAR
    left: !parsetree:LexicalSymbol
      context: CXT_SCALAR
      name: i
      sigil: $
    op: +
    right: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
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
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
expression: !parsetree:Symbol
  context: CXT_LIST
  name: a
  sigil: '@'
variable: !parsetree:Symbol
  context: CXT_SCALAR
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
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
expression: !parsetree:Symbol
  context: CXT_LIST
  name: a
  sigil: '@'
variable: !parsetree:Symbol
  context: CXT_SCALAR
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
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
expression: !parsetree:Symbol
  context: CXT_LIST
  name: a
  sigil: '@'
variable: !parsetree:LexicalDeclaration
  context: CXT_SCALAR
  declaration_type: my
  name: x
  sigil: $
EOE
