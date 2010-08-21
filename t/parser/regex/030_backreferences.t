#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/(a)\1/
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Pattern
  components:
    - !parsetree:RXGroup
      capture: 1
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: a
    - !parsetree:RXBackreference
      group: 1
  flags: 0
  op: OP_QL_M
  original: (?-xism:(a)\1)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/\1()\10/
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Pattern
  components:
    - !parsetree:RXBackreference
      group: 1
    - !parsetree:RXGroup
      capture: 1
      components: []
    - !parsetree:RXConstant
      insensitive: 0
      value: "\x08"
  flags: 0
  op: OP_QL_M
  original: (?-xism:\1()\10)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s/()/a\2\16/
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
      - !parsetree:RXGroup
        capture: 1
        components: []
    flags: 0
    op: OP_QL_S
    original: (?-xism:())
  replacement: !parsetree:QuotedString
    components:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: a
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: 2
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: "\x0e"
    context: CXT_SCALAR
EOE
