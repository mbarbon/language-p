#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 4;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/(?=test)/
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
    - !parsetree:RXAssertionGroup
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: test
      type: RX_GROUP_POSITIVE_LOOKAHEAD
  flags: 0
  op: OP_QL_M
  original: (?-xism:(?=test))
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/(?!test)/
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
    - !parsetree:RXAssertionGroup
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: test
      type: RX_GROUP_NEGATIVE_LOOKAHEAD
  flags: 0
  op: OP_QL_M
  original: (?-xism:(?!test))
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/(?<=test)/
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
    - !parsetree:RXAssertionGroup
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: test
      type: RX_GROUP_POSITIVE_LOOKBEHIND
  flags: 0
  op: OP_QL_M
  original: (?-xism:(?<=test))
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/(?<!test)/
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
    - !parsetree:RXAssertionGroup
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: test
      type: RX_GROUP_NEGATIVE_LOOKBEHIND
  flags: 0
  op: OP_QL_M
  original: (?-xism:(?<!test))
EOE
