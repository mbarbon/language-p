#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
our $foo;
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
my $foo;
our $foo;
package main;
$foo = 1;
EOP
--- !parsetree:LexicalState
hints: 0
package: x
warnings: ~
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY
name: foo
sigil: VALUE_SCALAR
--- !parsetree:Symbol
context: CXT_VOID
name: x::foo
sigil: VALUE_SCALAR
--- !parsetree:LexicalState
hints: 0
package: main
warnings: ~
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x::foo
  sigil: VALUE_SCALAR
op: 12
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE
