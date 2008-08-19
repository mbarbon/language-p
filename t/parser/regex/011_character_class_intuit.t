#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$x[1]/;
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
      - !parsetree:Subscript
        context: CXT_SCALAR
        reference: 0
        subscript: !parsetree:Constant
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
        subscripted: !parsetree:Symbol
          context: CXT_LIST
          name: x
          sigil: VALUE_ARRAY
        type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/${x[a]}/;
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
      - !parsetree:Subscript
        context: CXT_SCALAR
        reference: 0
        subscript: !parsetree:Constant
          flags: CONST_STRING|STRING_BARE
          value: a
        subscripted: !parsetree:Symbol
          context: CXT_LIST
          name: x
          sigil: VALUE_ARRAY
        type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$x[a]/;
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
        name: x
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        flags: CONST_STRING
        value: '[a]'
EOE
