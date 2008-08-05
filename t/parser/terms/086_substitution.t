#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s/foo/bar/g;
EOP
--- !parsetree:Substitution
pattern: !parsetree:Pattern
  components:
    - !parsetree:Constant
      type: string
      value: foo
  flags:
    - g
  op: s
replacement: !parsetree:Constant
  type: string
  value: bar
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s{foo}[$1];
EOP
--- !parsetree:Substitution
pattern: !parsetree:Pattern
  components:
    - !parsetree:Constant
      type: string
      value: foo
  flags: ~
  op: s
replacement: !parsetree:QuotedString
  components:
    - !parsetree:Symbol
      name: 1
      sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s{foo}'$1';
EOP
--- !parsetree:Substitution
pattern: !parsetree:Pattern
  components:
    - !parsetree:Constant
      type: string
      value: foo
  flags: ~
  op: s
replacement: !parsetree:Constant
  type: string
  value: $1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s/foo/my $x = 1; $x/ge;
EOP
--- !parsetree:Substitution
pattern: !parsetree:Pattern
  components:
    - !parsetree:Constant
      type: string
      value: foo
  flags:
    - g
    - e
  op: s
replacement: !parsetree:Block
  lines:
    - !parsetree:BinOp
      left: !parsetree:LexicalDeclaration
        declaration_type: my
        name: x
        sigil: $
      op: =
      right: !parsetree:Number
        flags: NUM_INTEGER
        type: number
        value: 1
    - !parsetree:LexicalSymbol
      name: x
      sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s/$foo/bar/g;
EOP
--- !parsetree:Substitution
pattern: !parsetree:InterpolatedPattern
  flags:
    - g
  op: s
  string: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        name: foo
        sigil: $
replacement: !parsetree:Constant
  type: string
  value: bar
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s'$foo'bar'g;
EOP
--- !parsetree:Substitution
pattern: !parsetree:Pattern
  components:
    - !parsetree:RXAssertion
      type: END_SPECIAL
    - !parsetree:Constant
      type: string
      value: foo
  flags:
    - g
  op: s
replacement: !parsetree:Constant
  type: string
  value: bar
EOE
