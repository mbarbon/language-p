#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 6;

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
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
        subscripted: !parsetree:Symbol
          context: CXT_LIST
          name: x
          sigil: VALUE_ARRAY
        type: VALUE_ARRAY
    context: CXT_SCALAR
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
          name: x
          sigil: VALUE_ARRAY
        type: VALUE_ARRAY
    context: CXT_SCALAR
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
  context: CXT_SCALAR
  flags: 0
  op: OP_QL_M
  string: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: x
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: '[a]'
    context: CXT_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$x[:]/;
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
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: x
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: '[:]'
    context: CXT_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$x[-$a]/;
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
        subscript: !parsetree:UnOp
          context: CXT_SCALAR
          left: !parsetree:Symbol
            context: CXT_SCALAR
            name: a
            sigil: VALUE_SCALAR
          op: OP_MINUS
        subscripted: !parsetree:Symbol
          context: CXT_LIST
          name: x
          sigil: VALUE_ARRAY
        type: VALUE_ARRAY
    context: CXT_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$x[$a-z]/;
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
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: x
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: '['
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: '-z]'
    context: CXT_SCALAR
EOE
