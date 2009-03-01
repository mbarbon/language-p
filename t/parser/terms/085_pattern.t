#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 8;

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
      type: START_SPECIAL
    - !parsetree:Constant
      flags: CONST_STRING
      value: test
    - !parsetree:RXAssertion
      type: END_SPECIAL
  flags: 0
  op: OP_QL_M
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
      type: START_SPECIAL
    - !parsetree:Constant
      flags: CONST_STRING
      value: test
  flags: 0
  op: OP_QL_M
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
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qr/^test/;
EOP
--- !parsetree:Pattern
components:
  - !parsetree:RXAssertion
    type: START_SPECIAL
  - !parsetree:Constant
    flags: CONST_STRING
    value: test
flags: 0
op: OP_QL_QR
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
      type: START_SPECIAL
    - !parsetree:RXAssertion
      type: END_SPECIAL
    - !parsetree:Constant
      flags: CONST_STRING
      value: '{foo}aaa'
  flags: 0
  op: OP_QL_M
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
EOE
