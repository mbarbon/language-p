#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 11;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/^test$/;
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
    - !parsetree:RXAssertion
      type: BEGINNING
    - !parsetree:RXConstant
      insensitive: 0
      value: test
    - !parsetree:RXAssertion
      type: END_OR_NEWLINE
  flags: 0
  op: OP_QL_M
  original: (?-xism:^test$)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a =~ /^test/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Pattern
  components:
    - !parsetree:RXAssertion
      type: BEGINNING
    - !parsetree:RXConstant
      insensitive: 0
      value: test
  flags: 0
  op: OP_QL_M
  original: (?-xism:^test)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a =~ "a";
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Pattern
  components:
    - !parsetree:RXConstant
      insensitive: 0
      value: a
  flags: 0
  op: OP_QL_M
  original: (?-xism:a)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a =~ $b;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:InterpolatedPattern
  context: CXT_SCALAR
  flags: 0
  op: OP_QL_M
  string: !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
//ms;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Pattern
  components: []
  flags: FLAG_RX_SINGLE_LINE|FLAG_RX_MULTI_LINE
  op: OP_QL_M
  original: (?sm-xi:)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qr/^test/;
EOP
--- !parsetree:Pattern
components:
  - !parsetree:RXAssertion
    type: BEGINNING
  - !parsetree:RXConstant
    insensitive: 0
    value: test
flags: 0
op: OP_QL_QR
original: (?-xism:^test)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
m/^${foo}aaa/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:InterpolatedPattern
  context: CXT_SCALAR
  flags: 0
  op: OP_QL_M
  string: !parsetree:QuotedString
    components:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: '^'
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: aaa
    context: CXT_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
m'^${foo}aaa';
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
    - !parsetree:RXAssertion
      type: BEGINNING
    - !parsetree:RXAssertion
      type: END_OR_NEWLINE
    - !parsetree:RXConstant
      insensitive: 0
      value: '{foo}aaa'
  flags: 0
  op: OP_QL_M
  original: '(?-xism:^${foo}aaa)'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$foo$/
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:InterpolatedPattern
  context: CXT_SCALAR
  flags: 0
  op: OP_QL_M
  string: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: $
    context: CXT_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$foo\w/
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:InterpolatedPattern
  context: CXT_SCALAR
  flags: 0
  op: OP_QL_M
  string: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: \w
    context: CXT_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/\/[\/\\]\\$foo/
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:InterpolatedPattern
  context: CXT_SCALAR
  flags: 0
  op: OP_QL_M
  string: !parsetree:QuotedString
    components:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: '/[/\\]\\'
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: VALUE_SCALAR
    context: CXT_SCALAR
EOE
