#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 8;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub name {
}
EOP
--- !parsetree:NamedSubroutine
lines: []
name: name
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub name { a }
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:Constant
        context: CXT_CALLER
        flags: CONST_STRING|STRING_BARE
        value: a
    context: CXT_CALLER
    function: OP_RETURN
name: name
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub name {
  $x
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:Symbol
        context: CXT_CALLER
        name: x
        sigil: VALUE_SCALAR
    context: CXT_CALLER
    function: OP_RETURN
name: name
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $x;
sub name {
  $x
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:LexicalSymbol
        context: CXT_CALLER
        level: 1
        name: x
        sigil: VALUE_SCALAR
    context: CXT_CALLER
    function: OP_RETURN
name: name
prototype: ~
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: x
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub name {
  my $x;
  $x
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    hints: 0
    package: main
    warnings: ~
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    flags: DECLARATION_MY
    name: x
    sigil: VALUE_SCALAR
  - !parsetree:Builtin
    arguments:
      - !parsetree:LexicalSymbol
        context: CXT_CALLER
        level: 0
        name: x
        sigil: VALUE_SCALAR
    context: CXT_CALLER
    function: OP_RETURN
name: name
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $x;
sub name {
  sub name2 {
    $x;
  }
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:LexicalSymbol
        context: CXT_CALLER
        level: 2
        name: x
        sigil: VALUE_SCALAR
    context: CXT_CALLER
    function: OP_RETURN
name: name2
prototype: ~
--- !parsetree:NamedSubroutine
lines: []
name: name
prototype: ~
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: x
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $x;
{
  sub name {
    $x
  }
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:LexicalSymbol
        context: CXT_CALLER
        level: 1
        name: x
        sigil: VALUE_SCALAR
    context: CXT_CALLER
    function: OP_RETURN
name: name
prototype: ~
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: x
sigil: VALUE_SCALAR
--- !parsetree:BareBlock
continue: ~
lines: []
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{
  my $x;
  sub name {
    $x
  }
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:LexicalSymbol
        context: CXT_CALLER
        level: 1
        name: x
        sigil: VALUE_SCALAR
    context: CXT_CALLER
    function: OP_RETURN
name: name
prototype: ~
--- !parsetree:BareBlock
continue: ~
lines:
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: x
    sigil: VALUE_SCALAR
EOE
