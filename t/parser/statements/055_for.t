#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

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
    level: 0
    name: i
    sigil: VALUE_SCALAR
  op: OP_NUM_LT
  right: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 10
continue: ~
initializer: !parsetree:BinOp
  context: CXT_VOID
  left: !parsetree:LexicalDeclaration
    context: CXT_SCALAR|CXT_LVALUE
    flags: DECLARATION_MY
    name: i
    sigil: VALUE_SCALAR
  op: OP_ASSIGN
  right: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 0
step: !parsetree:BinOp
  context: CXT_VOID
  left: !parsetree:LexicalSymbol
    context: CXT_SCALAR|CXT_LVALUE
    level: 0
    name: i
    sigil: VALUE_SCALAR
  op: OP_ASSIGN
  right: !parsetree:BinOp
    context: CXT_SCALAR
    left: !parsetree:LexicalSymbol
      context: CXT_SCALAR
      level: 0
      name: i
      sigil: VALUE_SCALAR
    op: OP_ADD
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
continue: ~
expression: !parsetree:Symbol
  context: CXT_LIST
  name: a
  sigil: VALUE_ARRAY
variable: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
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
continue: ~
expression: !parsetree:Symbol
  context: CXT_LIST
  name: a
  sigil: VALUE_ARRAY
variable: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: VALUE_SCALAR
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
continue: ~
expression: !parsetree:Symbol
  context: CXT_LIST
  name: a
  sigil: VALUE_ARRAY
variable: !parsetree:LexicalDeclaration
  context: CXT_SCALAR
  flags: DECLARATION_MY
  name: x
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foreach ( @a ) {
    1;
} continue {
    2;
}
EOP
--- !parsetree:Foreach
block: !parsetree:Block
  lines:
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
continue: !parsetree:Block
  lines:
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
expression: !parsetree:Symbol
  context: CXT_LIST
  name: a
  sigil: VALUE_ARRAY
variable: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
for my $x ( 8 ) {
  $x;
}
EOP
--- !parsetree:Foreach
block: !parsetree:Block
  lines:
    - !parsetree:LexicalSymbol
      context: CXT_VOID
      level: 0
      name: x
      sigil: VALUE_SCALAR
continue: ~
expression: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 8
variable: !parsetree:LexicalDeclaration
  context: CXT_SCALAR
  flags: DECLARATION_MY
  name: x
  sigil: VALUE_SCALAR
EOE
