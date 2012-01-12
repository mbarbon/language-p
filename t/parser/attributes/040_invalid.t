#!/usr/bin/perl -w

use t::lib::TestParser tests => 8;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar ! Baz
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Invalid separator character '!' in attribute list
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo :
EOP
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : = 1
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
my $foo : Bar ()
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Invalid separator character '(' in attribute list
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar('(')
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Unterminated attribute parameter in attribute list
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : 5x5
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Invalid attribute '5x5'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar::Baz
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Invalid separator character ':' in attribute list
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $foo : Bar :: Baz
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Invalid separator character ':' in attribute list
EOE
