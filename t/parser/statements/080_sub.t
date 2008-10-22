#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub name {
}
EOP
--- !parsetree:NamedSubroutine
lines: []
name: name
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub name {
  $x
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:Builtin
    arguments:
      - !parsetree:Symbol
        context: CXT_CALLER
        name: x
        sigil: VALUE_SCALAR
    context: CXT_CALLER
    function: return
name: name
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $x;
sub name {
  $x
}
EOP
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: x
sigil: VALUE_SCALAR
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:Builtin
    arguments:
      - !parsetree:LexicalSymbol
        context: CXT_CALLER
        level: 1
        name: x
        sigil: VALUE_SCALAR
    context: CXT_CALLER
    function: return
name: name
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub name {
  my $x;
  $x
}
EOP
--- !parsetree:NamedSubroutine
lines:
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
    function: return
name: name
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $x;
sub name {
  sub name2 {
    $x;
  }
}
EOP
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: x
sigil: VALUE_SCALAR
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:NamedSubroutine
    lines:
      - !parsetree:Builtin
        arguments:
          - !parsetree:LexicalSymbol
            context: CXT_CALLER
            level: 2
            name: x
            sigil: VALUE_SCALAR
        context: CXT_CALLER
        function: return
    name: name2
name: name
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $x;
{
  sub name {
    $x
  }
}
EOP
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: x
sigil: VALUE_SCALAR
--- !parsetree:Block
lines:
  - !parsetree:NamedSubroutine
    lines:
      - !parsetree:Builtin
        arguments:
          - !parsetree:LexicalSymbol
            context: CXT_CALLER
            level: 1
            name: x
            sigil: VALUE_SCALAR
        context: CXT_CALLER
        function: return
    name: name
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{
  my $x;
  sub name {
    $x
  }
}
EOP
--- !parsetree:Block
lines:
  - !parsetree:LexicalDeclaration
    context: CXT_VOID
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: x
    sigil: VALUE_SCALAR
  - !parsetree:NamedSubroutine
    lines:
      - !parsetree:Builtin
        arguments:
          - !parsetree:LexicalSymbol
            context: CXT_CALLER
            level: 1
            name: x
            sigil: VALUE_SCALAR
        context: CXT_CALLER
        function: return
    name: name
EOE
