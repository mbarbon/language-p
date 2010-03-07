#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$c = sub {
  1
};
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: c
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:AnonymousSubroutine
  lines:
    - !parsetree:LexicalState
      changed: CHANGED_ALL
      hints: 0
      package: main
      warnings: ~
    - !parsetree:Builtin
      arguments:
        - !parsetree:Constant
          context: CXT_CALLER
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
      context: CXT_CALLER
      function: OP_RETURN
  prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
my $d = 1;
$c = sub {
  $d;
};
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:LexicalDeclaration
  context: CXT_SCALAR|CXT_LVALUE
  flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
  name: d
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: c
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:AnonymousSubroutine
  lines:
    - !parsetree:LexicalState
      changed: CHANGED_ALL
      hints: 0
      package: main
      warnings: ~
    - !parsetree:Builtin
      arguments:
        - !parsetree:LexicalSymbol
          context: CXT_CALLER
          level: 1
          name: d
          sigil: VALUE_SCALAR
      context: CXT_CALLER
      function: OP_RETURN
  prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub add3 {
    my($x) = @_;

    return sub {
        my($y) = @_;

        return sub {
            my($z) = @_;

            return $x + $y + $z;
        };
    };
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:LexicalState
    changed: CHANGED_ALL
    hints: 0
    package: main
    warnings: ~
  - !parsetree:BinOp
    context: CXT_VOID
    left: !parsetree:List
      context: CXT_LIST|CXT_LVALUE
      expressions:
        - !parsetree:LexicalDeclaration
          context: CXT_SCALAR|CXT_LVALUE
          flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
          name: x
          sigil: VALUE_SCALAR
    op: OP_ASSIGN
    right: !parsetree:LexicalSymbol
      context: CXT_LIST
      level: 0
      name: _
      sigil: VALUE_ARRAY
  - !parsetree:Builtin
    arguments:
      - !parsetree:AnonymousSubroutine
        lines:
          - !parsetree:LexicalState
            changed: CHANGED_ALL
            hints: 0
            package: main
            warnings: ~
          - !parsetree:BinOp
            context: CXT_VOID
            left: !parsetree:List
              context: CXT_LIST|CXT_LVALUE
              expressions:
                - !parsetree:LexicalDeclaration
                  context: CXT_SCALAR|CXT_LVALUE
                  flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
                  name: y
                  sigil: VALUE_SCALAR
            op: OP_ASSIGN
            right: !parsetree:LexicalSymbol
              context: CXT_LIST
              level: 0
              name: _
              sigil: VALUE_ARRAY
          - !parsetree:Builtin
            arguments:
              - !parsetree:AnonymousSubroutine
                lines:
                  - !parsetree:LexicalState
                    changed: CHANGED_ALL
                    hints: 0
                    package: main
                    warnings: ~
                  - !parsetree:BinOp
                    context: CXT_VOID
                    left: !parsetree:List
                      context: CXT_LIST|CXT_LVALUE
                      expressions:
                        - !parsetree:LexicalDeclaration
                          context: CXT_SCALAR|CXT_LVALUE
                          flags: DECLARATION_MY
                          name: z
                          sigil: VALUE_SCALAR
                    op: OP_ASSIGN
                    right: !parsetree:LexicalSymbol
                      context: CXT_LIST
                      level: 0
                      name: _
                      sigil: VALUE_ARRAY
                  - !parsetree:Builtin
                    arguments:
                      - !parsetree:BinOp
                        context: CXT_CALLER
                        left: !parsetree:BinOp
                          context: CXT_SCALAR
                          left: !parsetree:LexicalSymbol
                            context: CXT_SCALAR
                            level: 2
                            name: x
                            sigil: VALUE_SCALAR
                          op: OP_ADD
                          right: !parsetree:LexicalSymbol
                            context: CXT_SCALAR
                            level: 1
                            name: y
                            sigil: VALUE_SCALAR
                        op: OP_ADD
                        right: !parsetree:LexicalSymbol
                          context: CXT_SCALAR
                          level: 0
                          name: z
                          sigil: VALUE_SCALAR
                    context: CXT_CALLER
                    function: OP_RETURN
                prototype: ~
            context: CXT_CALLER
            function: OP_RETURN
        prototype: ~
    context: CXT_CALLER
    function: OP_RETURN
name: add3
prototype: ~
EOE
