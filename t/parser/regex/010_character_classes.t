#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[abc]/;
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
    - !parsetree:RXClass
      elements:
        - !parsetree:Constant
          flags: CONST_STRING
          value: a
        - !parsetree:Constant
          flags: CONST_STRING
          value: b
        - !parsetree:Constant
          flags: CONST_STRING
          value: c
      insensitive: 0
  flags: 0
  op: OP_QL_M
  original: '(?-xism:[abc])'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[a-q]/;
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
    - !parsetree:RXClass
      elements:
        - !parsetree:RXRange
          end: q
          start: a
      insensitive: 0
  flags: 0
  op: OP_QL_M
  original: '(?-xism:[a-q])'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[a-]/;
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
    - !parsetree:RXClass
      elements:
        - !parsetree:Constant
          flags: CONST_STRING
          value: a
        - !parsetree:Constant
          flags: CONST_STRING
          value: -
      insensitive: 0
  flags: 0
  op: OP_QL_M
  original: '(?-xism:[a-])'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[a-\w]/;
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
    - !parsetree:RXClass
      elements:
        - !parsetree:Constant
          flags: CONST_STRING
          value: a
        - !parsetree:Constant
          flags: CONST_STRING
          value: -
        - !parsetree:RXSpecialClass
          type: RX_CLASS_WORDS
      insensitive: 0
  flags: 0
  op: OP_QL_M
  original: '(?-xism:[a-\w])'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[[\]]/;
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
    - !parsetree:RXClass
      elements:
        - !parsetree:Constant
          flags: CONST_STRING
          value: '['
        - !parsetree:Constant
          flags: CONST_STRING
          value: ']'
      insensitive: 0
  flags: 0
  op: OP_QL_M
  original: '(?-xism:[[\]])'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[[]]/;
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
    - !parsetree:RXClass
      elements:
        - !parsetree:Constant
          flags: CONST_STRING
          value: '['
      insensitive: 0
    - !parsetree:RXConstant
      insensitive: 0
      value: ']'
  flags: 0
  op: OP_QL_M
  original: '(?-xism:[[]])'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[\/\\]/
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
    - !parsetree:RXClass
      elements:
        - !parsetree:Constant
          flags: CONST_STRING
          value: /
        - !parsetree:Constant
          flags: CONST_STRING
          value: \
      insensitive: 0
  flags: 0
  op: OP_QL_M
  original: '(?-xism:[/\\])'
EOE
