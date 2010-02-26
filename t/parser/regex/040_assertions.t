#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

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
        - !parsetree:Constant
          flags: CONST_STRING
          value: test
      type: POSITIVE_LOOKAHEAD
  flags: 0
  op: OP_QL_M
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
        - !parsetree:Constant
          flags: CONST_STRING
          value: test
      type: NEGATIVE_LOOKBEHIND
  flags: 0
  op: OP_QL_M
EOE
