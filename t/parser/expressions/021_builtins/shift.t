#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my @foo;
shift foo;
EOP
--- !parsetree:LexicalDeclaration
context: CXT_VOID
flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
name: foo
sigil: VALUE_ARRAY
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_ARRAY_SHIFT
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub a { shift }
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:Overridable
        arguments:
          - !parsetree:LexicalSymbol
            context: CXT_LIST
            level: 0
            name: _
            sigil: VALUE_ARRAY
        context: CXT_CALLER
        function: OP_ARRAY_SHIFT
    context: CXT_CALLER
    function: OP_RETURN
name: a
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub { shift };
EOP
--- !parsetree:AnonymousSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:Builtin
    arguments:
      - !parsetree:Overridable
        arguments:
          - !parsetree:LexicalSymbol
            context: CXT_LIST
            level: 0
            name: _
            sigil: VALUE_ARRAY
        context: CXT_CALLER
        function: OP_ARRAY_SHIFT
    context: CXT_CALLER
    function: OP_RETURN
prototype: ~
EOE
