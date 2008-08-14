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
      type: string
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
        type: string
        value: a
    - !parsetree:RXQuantifier
      greedy: 1
      max: -1
      min: 1
      node: !parsetree:Constant
        type: string
        value: b
    - !parsetree:RXQuantifier
      greedy: 1
      max: 1
      min: 0
      node: !parsetree:Constant
        type: string
        value: c
    - !parsetree:RXQuantifier
      greedy: 0
      max: -1
      min: 0
      node: !parsetree:Constant
        type: string
        value: d
    - !parsetree:RXQuantifier
      greedy: 0
      max: -1
      min: 1
      node: !parsetree:Constant
        type: string
        value: b
    - !parsetree:RXQuantifier
      greedy: 0
      max: 1
      min: 0
      node: !parsetree:Constant
        type: string
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
            type: string
            value: a
          - !parsetree:RXQuantifier
            greedy: 0
            max: 1
            min: 0
            node: !parsetree:RXGroup
              capture: 1
              components:
                - !parsetree:Constant
                  type: string
                  value: cbc
          - !parsetree:Constant
            type: string
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
          type: string
          value: t
      right:
        - !parsetree:RXAlternation
          left:
            - !parsetree:Constant
              type: string
              value: es
          right:
            - !parsetree:Constant
              type: string
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
        type: string
        value: a
    - !parsetree:RXGroup
      capture: 1
      components:
        - !parsetree:RXAlternation
          left:
            - !parsetree:Constant
              type: string
              value: a
          right:
            - !parsetree:RXAlternation
              left:
                - !parsetree:Constant
                  type: string
                  value: b
              right:
                - !parsetree:Constant
                  type: string
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
      type: string
      value: a
    - !parsetree:RXGroup
      capture: 0
      components:
        - !parsetree:Constant
          type: string
          value: a
    - !parsetree:RXGroup
      capture: 1
      components:
        - !parsetree:Constant
          type: string
          value: a
  flags: ~
  op: m
EOE
