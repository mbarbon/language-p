#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
m/^\ntest\w/;
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
      flags: CONST_STRING
      value: "\ntest"
    - !parsetree:RXSpecialClass
      type: WORDS
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a*b+c?d*?b+?c??/;
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
    - !parsetree:RXQuantifier
      greedy: 1
      max: -1
      min: 0
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
    - !parsetree:RXQuantifier
      greedy: 1
      max: -1
      min: 1
      node: !parsetree:Constant
        flags: CONST_STRING
        value: b
    - !parsetree:RXQuantifier
      greedy: 1
      max: 1
      min: 0
      node: !parsetree:Constant
        flags: CONST_STRING
        value: c
    - !parsetree:RXQuantifier
      greedy: 0
      max: -1
      min: 0
      node: !parsetree:Constant
        flags: CONST_STRING
        value: d
    - !parsetree:RXQuantifier
      greedy: 0
      max: -1
      min: 1
      node: !parsetree:Constant
        flags: CONST_STRING
        value: b
    - !parsetree:RXQuantifier
      greedy: 0
      max: 1
      min: 0
      node: !parsetree:Constant
        flags: CONST_STRING
        value: c
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/(a(cbc)??w)*/;
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
    - !parsetree:RXQuantifier
      greedy: 1
      max: -1
      min: 0
      node: !parsetree:RXGroup
        capture: 1
        components:
          - !parsetree:Constant
            flags: CONST_STRING
            value: a
          - !parsetree:RXQuantifier
            greedy: 0
            max: 1
            min: 0
            node: !parsetree:RXGroup
              capture: 1
              components:
                - !parsetree:Constant
                  flags: CONST_STRING
                  value: cbc
          - !parsetree:Constant
            flags: CONST_STRING
            value: w
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/^t|es|t$/;
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
    - !parsetree:RXAlternation
      left:
        - !parsetree:RXAssertion
          type: START_SPECIAL
        - !parsetree:Constant
          flags: CONST_STRING
          value: t
      right:
        - !parsetree:RXAlternation
          left:
            - !parsetree:Constant
              flags: CONST_STRING
              value: es
          right:
            - !parsetree:Constant
              flags: CONST_STRING
              value: t
            - !parsetree:RXAssertion
              type: END_SPECIAL
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a+(a|b|c)/;
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
    - !parsetree:RXQuantifier
      greedy: 1
      max: -1
      min: 1
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
    - !parsetree:RXGroup
      capture: 1
      components:
        - !parsetree:RXAlternation
          left:
            - !parsetree:Constant
              flags: CONST_STRING
              value: a
          right:
            - !parsetree:RXAlternation
              left:
                - !parsetree:Constant
                  flags: CONST_STRING
                  value: b
              right:
                - !parsetree:Constant
                  flags: CONST_STRING
                  value: c
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a(?:a)(a)/;
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
    - !parsetree:Constant
      flags: CONST_STRING
      value: a
    - !parsetree:RXGroup
      capture: 0
      components:
        - !parsetree:Constant
          flags: CONST_STRING
          value: a
    - !parsetree:RXGroup
      capture: 1
      components:
        - !parsetree:Constant
          flags: CONST_STRING
          value: a
  flags: ~
  op: m
EOE
