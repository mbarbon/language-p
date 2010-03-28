#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
bless $foo, 'Foo'
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: Foo
context: CXT_VOID
function: OP_BLESS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package Foo;
bless $foo
EOP
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: Foo
warnings: ~
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: Foo::foo
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: Foo
context: CXT_VOID
function: OP_BLESS
EOE
