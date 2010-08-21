#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 8;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
m/^\ntes.\.\w/;
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
      value: "\ntes"
    - !parsetree:RXAssertion
      type: ANY_NONEWLINE
    - !parsetree:RXConstant
      insensitive: 0
      value: .
    - !parsetree:RXSpecialClass
      type: WORDS
  flags: 0
  op: OP_QL_M
  original: (?-xism:^\ntes.\.\w)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a*b+c?d*?b+?c??/;
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
    - !parsetree:RXQuantifier
      greedy: 1
      max: -1
      min: 0
      node: !parsetree:RXConstant
        insensitive: 0
        value: a
    - !parsetree:RXQuantifier
      greedy: 1
      max: -1
      min: 1
      node: !parsetree:RXConstant
        insensitive: 0
        value: b
    - !parsetree:RXQuantifier
      greedy: 1
      max: 1
      min: 0
      node: !parsetree:RXConstant
        insensitive: 0
        value: c
    - !parsetree:RXQuantifier
      greedy: 0
      max: -1
      min: 0
      node: !parsetree:RXConstant
        insensitive: 0
        value: d
    - !parsetree:RXQuantifier
      greedy: 0
      max: -1
      min: 1
      node: !parsetree:RXConstant
        insensitive: 0
        value: b
    - !parsetree:RXQuantifier
      greedy: 0
      max: 1
      min: 0
      node: !parsetree:RXConstant
        insensitive: 0
        value: c
  flags: 0
  op: OP_QL_M
  original: (?-xism:a*b+c?d*?b+?c??)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/(a(cbc)??w)*/;
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
    - !parsetree:RXQuantifier
      greedy: 1
      max: -1
      min: 0
      node: !parsetree:RXGroup
        capture: 1
        components:
          - !parsetree:RXConstant
            insensitive: 0
            value: a
          - !parsetree:RXQuantifier
            greedy: 0
            max: 1
            min: 0
            node: !parsetree:RXGroup
              capture: 1
              components:
                - !parsetree:RXConstant
                  insensitive: 0
                  value: cbc
          - !parsetree:RXConstant
            insensitive: 0
            value: w
  flags: 0
  op: OP_QL_M
  original: (?-xism:(a(cbc)??w)*)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/^t|es|t$/;
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
    - !parsetree:RXAlternation
      left:
        - !parsetree:RXAssertion
          type: BEGINNING
        - !parsetree:RXConstant
          insensitive: 0
          value: t
      right:
        - !parsetree:RXAlternation
          left:
            - !parsetree:RXConstant
              insensitive: 0
              value: es
          right:
            - !parsetree:RXConstant
              insensitive: 0
              value: t
            - !parsetree:RXAssertion
              type: END_OR_NEWLINE
  flags: 0
  op: OP_QL_M
  original: (?-xism:^t|es|t$)
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a+(a|b|c)/;
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
    - !parsetree:RXQuantifier
      greedy: 1
      max: -1
      min: 1
      node: !parsetree:RXConstant
        insensitive: 0
        value: a
    - !parsetree:RXGroup
      capture: 1
      components:
        - !parsetree:RXAlternation
          left:
            - !parsetree:RXConstant
              insensitive: 0
              value: a
          right:
            - !parsetree:RXAlternation
              left:
                - !parsetree:RXConstant
                  insensitive: 0
                  value: b
              right:
                - !parsetree:RXConstant
                  insensitive: 0
                  value: c
  flags: 0
  op: OP_QL_M
  original: (?-xism:a+(a|b|c))
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a(?:a)(a)/;
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
    - !parsetree:RXConstant
      insensitive: 0
      value: a
    - !parsetree:RXGroup
      capture: 0
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: a
    - !parsetree:RXGroup
      capture: 1
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: a
  flags: 0
  op: OP_QL_M
  original: (?-xism:a(?:a)(a))
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a(?i-s:a.)/s;
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
    - !parsetree:RXConstant
      insensitive: 0
      value: a
    - !parsetree:RXGroup
      capture: 0
      components:
        - !parsetree:RXConstant
          insensitive: FLAG_RX_CASE_INSENSITIVE
          value: a
        - !parsetree:RXAssertion
          type: ANY_NONEWLINE
  flags: FLAG_RX_SINGLE_LINE
  op: OP_QL_M
  original: (?s-xim:a(?i-s:a.))
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a(?:a.(?i-s)a.)/s;
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
    - !parsetree:RXConstant
      insensitive: 0
      value: a
    - !parsetree:RXGroup
      capture: 0
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: a
        - !parsetree:RXAssertion
          type: ANY
        - !parsetree:RXConstant
          insensitive: FLAG_RX_CASE_INSENSITIVE
          value: a
        - !parsetree:RXAssertion
          type: ANY_NONEWLINE
  flags: FLAG_RX_SINGLE_LINE
  op: OP_QL_M
  original: (?s-xim:a(?:a.(?i-s)a.))
EOE
