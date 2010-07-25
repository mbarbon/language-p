#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
grep { @y } @x;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_GREP
indirect: !parsetree:Block
  lines:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: y
      sigil: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
grep /test/, @x;
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:BinOp
    context: CXT_SCALAR
    left: !parsetree:Symbol
      context: CXT_SCALAR
      name: _
      sigil: VALUE_SCALAR
    op: OP_MATCH
    right: !parsetree:Pattern
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: test
      flags: 0
      op: OP_QL_M
  - !parsetree:Symbol
    context: CXT_LIST
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_GREP
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
grep( /test/, @x );
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:BinOp
    context: CXT_SCALAR
    left: !parsetree:Symbol
      context: CXT_SCALAR
      name: _
      sigil: VALUE_SCALAR
    op: OP_MATCH
    right: !parsetree:Pattern
      components:
        - !parsetree:RXConstant
          insensitive: 0
          value: test
      flags: 0
      op: OP_QL_M
  - !parsetree:Symbol
    context: CXT_LIST
    name: x
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_GREP
indirect: ~
EOE
