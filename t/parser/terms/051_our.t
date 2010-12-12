#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 3;

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
changed: CHANGED_PACKAGE
hints: 0
package: x
warnings: ~
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
--- !parsetree:Symbol
context: CXT_VOID
name: x::foo
sigil: VALUE_SCALAR
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: main
warnings: ~
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x::foo
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
our $foo::bar;
EOP
--- !p:Exception
file: '<string>'
line: 1
message: No package name allowed for variable $foo::bar in "our"
EOE
