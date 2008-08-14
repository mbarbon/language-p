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
  sigil: $
op: =~
right: !parsetree:Pattern
  components:
    - !parsetree:RXAssertion
      type: START_SPECIAL
    - !parsetree:Constant
      type: string
      value: test
    - !parsetree:RXAssertion
      type: END_SPECIAL
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a =~ /^test/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: $
op: =~
right: !parsetree:Pattern
  components:
    - !parsetree:RXAssertion
      type: START_SPECIAL
    - !parsetree:Constant
      type: string
      value: test
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
//ms;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: $
op: =~
right: !parsetree:Pattern
  components: []
  flags:
    - m
    - s
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qr/^test/;
EOP
--- !parsetree:Pattern
components:
  - !parsetree:RXAssertion
    type: START_SPECIAL
  - !parsetree:Constant
    type: string
    value: test
flags: ~
op: qr
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
m/^${foo}aaa/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: $
op: =~
right: !parsetree:InterpolatedPattern
  flags: ~
  op: m
  string: !parsetree:QuotedString
    components:
      - !parsetree:Constant
        type: string
        value: '^'
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: $
      - !parsetree:Constant
        type: string
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
  sigil: $
op: =~
right: !parsetree:Pattern
  components:
    - !parsetree:RXAssertion
      type: START_SPECIAL
    - !parsetree:RXAssertion
      type: END_SPECIAL
    - !parsetree:Constant
      type: string
      value: '{foo}aaa'
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$foo$/
EOP
--- !parsetree:BinOp
context: 2
left: !parsetree:Symbol
  context: 4
  name: _
  sigil: $
op: =~
right: !parsetree:InterpolatedPattern
  flags: ~
  op: m
  string: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: 4
        name: foo
        sigil: $
      - !parsetree:Constant
        type: string
        value: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$foo\w/
EOP
--- !parsetree:BinOp
context: 2
left: !parsetree:Symbol
  context: 4
  name: _
  sigil: $
op: =~
right: !parsetree:InterpolatedPattern
  flags: ~
  op: m
  string: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: 4
        name: foo
        sigil: $
      - !parsetree:Constant
        type: string
        value: \w
EOE
