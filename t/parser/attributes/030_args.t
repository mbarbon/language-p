#!/usr/bin/perl -w

use t::lib::TestParser tests => 4;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar()
EOP
--- !parsetree:LexicalDeclaration
attributes:
  - Bar()
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar(roo(), moo(), foo())
EOP
--- !parsetree:LexicalDeclaration
attributes:
  - 'Bar(roo(), moo(), foo())'
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar('\(")
EOP
--- !parsetree:LexicalDeclaration
attributes:
  - Bar('\(")
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : _5x5
EOP
--- !parsetree:LexicalDeclaration
attributes:
  - _5x5
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE
