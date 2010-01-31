#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 12;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a*/;
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
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a??/;
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
      greedy: 0
      max: 1
      min: 0
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a{,2}/;
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
    - !parsetree:Constant
      flags: CONST_STRING
      value: 'a{,2}'
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a{7}/;
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
      max: 7
      min: 7
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a{7}?/;
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
      greedy: 0
      max: 7
      min: 7
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a{1,2}/;
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
      max: 2
      min: 1
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a{1,2}?/;
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
      greedy: 0
      max: 2
      min: 1
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a{4,}/;
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
      min: 4
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/a{5,}?/;
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
      greedy: 0
      max: -1
      min: 5
      node: !parsetree:Constant
        flags: CONST_STRING
        value: a
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$a{a}/;
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
      - !parsetree:Subscript
        context: CXT_SCALAR
        reference: 0
        subscript: !parsetree:Constant
          context: CXT_SCALAR
          flags: CONST_STRING|STRING_BARE
          value: a
        subscripted: !parsetree:Symbol
          context: CXT_LIST
          name: a
          sigil: VALUE_HASH
        type: VALUE_HASH
    context: CXT_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$a{5}/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: 134
right: !parsetree:InterpolatedPattern
  context: CXT_SCALAR
  flags: 0
  op: OP_QL_M
  string: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: '{5}'
    context: CXT_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$a{5,7}/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: 134
right: !parsetree:InterpolatedPattern
  context: CXT_SCALAR
  flags: 0
  op: OP_QL_M
  string: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: '{5,7}'
    context: CXT_SCALAR
EOE
