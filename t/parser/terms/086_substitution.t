#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s/foo/bar/g;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Substitution
  pattern: !parsetree:Pattern
    components:
      - !parsetree:Constant
        flags: CONST_STRING
        value: foo
    flags: FLAG_RX_GLOBAL
    op: OP_QL_S
  replacement: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: bar
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s{foo}[$1];
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Substitution
  pattern: !parsetree:Pattern
    components:
      - !parsetree:Constant
        flags: CONST_STRING
        value: foo
    flags: 0
    op: OP_QL_S
  replacement: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: 1
        sigil: VALUE_SCALAR
    context: CXT_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s{foo}'$1';
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Substitution
  pattern: !parsetree:Pattern
    components:
      - !parsetree:Constant
        flags: CONST_STRING
        value: foo
    flags: 0
    op: OP_QL_S
  replacement: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: $1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s/foo/my $x = 1; $x/ge;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Substitution
  pattern: !parsetree:Pattern
    components:
      - !parsetree:Constant
        flags: CONST_STRING
        value: foo
    flags: FLAG_RX_GLOBAL|FLAG_RX_EVAL
    op: OP_QL_S
  replacement: !parsetree:Block
    lines:
      - !parsetree:BinOp
        context: CXT_VOID
        left: !parsetree:LexicalDeclaration
          context: CXT_SCALAR|CXT_LVALUE
          flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
          name: x
          sigil: VALUE_SCALAR
        op: OP_ASSIGN
        right: !parsetree:Constant
          context: CXT_SCALAR
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
      - !parsetree:LexicalSymbol
        context: CXT_SCALAR
        level: 0
        name: x
        sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s/$foo/bar/g;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Substitution
  pattern: !parsetree:InterpolatedPattern
    context: CXT_SCALAR
    flags: FLAG_RX_GLOBAL
    op: OP_QL_S
    string: !parsetree:QuotedString
      components:
        - !parsetree:Symbol
          context: CXT_SCALAR
          name: foo
          sigil: VALUE_SCALAR
      context: CXT_SCALAR
  replacement: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: bar
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s'$foo'bar'g;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Substitution
  pattern: !parsetree:Pattern
    components:
      - !parsetree:RXAssertion
        type: END_OR_NEWLINE
      - !parsetree:Constant
        flags: CONST_STRING
        value: foo
    flags: FLAG_RX_GLOBAL
    op: OP_QL_S
  replacement: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: bar
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s/foo/substr(<<EOT, 3)/e;
xxxbaz
EOTi
 EOT
EOT
# 1;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Substitution
  pattern: !parsetree:Pattern
    components:
      - !parsetree:Constant
        flags: CONST_STRING
        value: foo
    flags: FLAG_RX_EVAL
    op: OP_QL_S
  replacement: !parsetree:Block
    lines:
      - !parsetree:Overridable
        arguments:
          - !parsetree:Constant
            context: CXT_SCALAR
            flags: CONST_STRING
            value: "xxxbaz\nEOTi\n EOT\n"
          - !parsetree:Constant
            context: CXT_SCALAR
            flags: CONST_NUMBER|NUM_INTEGER
            value: 3
        context: CXT_SCALAR
        function: OP_SUBSTR
EOE
