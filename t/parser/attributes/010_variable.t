#!/usr/bin/perl -w

use t::lib::TestParser tests => 4;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar
EOP
--- !parsetree:LexicalDeclaration
attributes:
  - Bar
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
our $foo : Bar
EOP
--- !parsetree:Symbol
attributes:
  - Bar
context: CXT_VOID
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my( $foo, $bar ) : Bar
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:LexicalDeclaration
    attributes:
      - Bar
    context: CXT_VOID
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: foo
    sigil: VALUE_SCALAR
  - !parsetree:LexicalDeclaration
    attributes:
      - Bar
    context: CXT_VOID
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: bar
    sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my( $foo, $bar ) : Bar = 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:List
  context: CXT_LIST|CXT_LVALUE
  expressions:
    - !parsetree:LexicalDeclaration
      attributes:
        - Bar
      context: CXT_SCALAR|CXT_LVALUE
      flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
      name: foo
      sigil: VALUE_SCALAR
    - !parsetree:LexicalDeclaration
      attributes:
        - Bar
      context: CXT_SCALAR|CXT_LVALUE
      flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
      name: bar
      sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_LIST
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE
