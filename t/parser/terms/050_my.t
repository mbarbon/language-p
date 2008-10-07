#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo;
EOP
--- !parsetree:LexicalDeclaration
context: CXT_VOID
declaration_type: OP_MY
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo = 1;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:LexicalDeclaration
  context: CXT_SCALAR|CXT_LVALUE
  declaration_type: OP_MY
  name: foo
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my( $foo, @bar ) = ( 1, 2, 3 );
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:List
  expressions:
    - !parsetree:LexicalDeclaration
      context: CXT_SCALAR|CXT_LVALUE
      declaration_type: OP_MY
      name: foo
      sigil: VALUE_SCALAR
    - !parsetree:LexicalDeclaration
      context: CXT_LIST|CXT_LVALUE
      declaration_type: OP_MY
      name: bar
      sigil: VALUE_ARRAY
op: OP_ASSIGN
right: !parsetree:List
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
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my( ${foo} );
EOP
--- !parsetree:List
expressions:
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    declaration_type: OP_MY
    name: foo
    sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my( ${foo}, @{b}, $x );
EOP
--- !parsetree:List
expressions:
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    declaration_type: OP_MY
    name: foo
    sigil: VALUE_SCALAR
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    declaration_type: OP_MY
    name: b
    sigil: VALUE_ARRAY
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    declaration_type: OP_MY
    name: x
    sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $x;
my $x = $x;
EOP
--- !parsetree:LexicalDeclaration
context: CXT_VOID
declaration_type: OP_MY
name: x
sigil: VALUE_SCALAR
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:LexicalDeclaration
  context: CXT_SCALAR|CXT_LVALUE
  declaration_type: OP_MY
  name: x
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:LexicalSymbol
  context: CXT_SCALAR
  name: x
  sigil: VALUE_SCALAR
EOE

