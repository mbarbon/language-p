#!/usr/bin/perl -w

use t::lib::TestParser tests => 8;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 = 1
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Can't modify constant
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 += 1
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Can't modify constant
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
( $a, 1 ) = 1
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Can't modify constant
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
( $x ? 1 : 2 ) = 1
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Can't modify constant
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print( $x ) = 1
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Can't modify print
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
undef = 1
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Builtin
  arguments: ~
  context: CXT_SCALAR|CXT_LVALUE
  function: OP_UNDEF
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
( undef ) = 1
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Parentheses
  context: CXT_LIST|CXT_LVALUE
  left: !parsetree:Builtin
    arguments: ~
    context: CXT_LIST|CXT_LVALUE
    function: OP_UNDEF
  op: OP_PARENTHESES
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_LIST
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
substr( $x, 0, 1, 2 ) = 1
EOP
--- !p:Exception
file: '<string>'
line: 1
message: Can't modify substr
EOE
