#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar : Baz
EOP
--- !parsetree:LexicalDeclaration
attributes:
  - Bar
  - Baz
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar Baz
EOP
--- !parsetree:LexicalDeclaration
attributes:
  - Bar
  - Baz
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar Baz : Boo : Roo Moo
EOP
--- !parsetree:LexicalDeclaration
attributes:
  - Bar
  - Baz
  - Boo
  - Roo
  - Moo
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE
