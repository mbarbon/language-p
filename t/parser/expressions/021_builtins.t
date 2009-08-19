#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 8;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
push @foo, 1, 2;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
function: OP_ARRAY_PUSH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
pop foo;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_ARRAY_POP
EOE

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
chr
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_CHR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-t
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: STDIN
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_FT_ISTTY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
pop
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: ARGV
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_ARRAY_POP
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
EOE
