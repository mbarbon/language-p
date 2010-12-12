#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 11;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo;
EOP
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my( $foo, undef );
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: foo
    sigil: VALUE_SCALAR
  - !parsetree:Builtin
    arguments: ~
    context: CXT_VOID
    function: OP_UNDEF
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo = 1;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:LexicalDeclaration
  context: CXT_SCALAR|CXT_LVALUE
  flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
  name: foo
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my( $foo, @bar ) = ( 1, 2, 3 );
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:List
  context: CXT_LIST|CXT_LVALUE
  expressions:
    - !parsetree:LexicalDeclaration
      context: CXT_SCALAR|CXT_LVALUE
      flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
      name: foo
      sigil: VALUE_SCALAR
    - !parsetree:LexicalDeclaration
      context: CXT_LIST|CXT_LVALUE
      flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
      name: bar
      sigil: VALUE_ARRAY
op: OP_ASSIGN
right: !parsetree:List
  context: CXT_LIST
  expressions:
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
    - !parsetree:Constant
      context: CXT_LIST
      flags: CONST_NUMBER|NUM_INTEGER
      value: 3
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my( ${foo} );
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: foo
    sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my( ${foo}, @{b}, $x );
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: foo
    sigil: VALUE_SCALAR
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: b
    sigil: VALUE_ARRAY
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: x
    sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $x;
my $x = $x;
EOP
--- !parsetree:LexicalDeclaration
context: CXT_VOID 
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: x
sigil: VALUE_SCALAR
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:LexicalDeclaration
  context: CXT_SCALAR|CXT_LVALUE
  flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
  name: x
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:LexicalSymbol
  context: CXT_SCALAR
  level: 0
  name: x
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $x = ${"foo"};
$x;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:LexicalDeclaration
  context: CXT_SCALAR|CXT_LVALUE
  flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
  name: x
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Block
    lines:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: foo
  op: OP_DEREFERENCE_SCALAR
--- !parsetree:LexicalSymbol
context: CXT_VOID
level: 0
name: x
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my ${^FOO};
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Can't use global $^FOO in "my"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $&;
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Can't use global $& in "my"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo::bar;
EOP
--- !p:Exception
file: '<string>'
line: 1
message: "\"my\" variable $foo::bar can't be in a package"
EOE
