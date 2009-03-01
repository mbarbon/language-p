#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
+12
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 12
op: OP_PLUS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-12
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 12
op: OP_MINUS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-( 1 )
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Parentheses
  context: CXT_SCALAR
  left: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  op: OP_PARENTHESES
op: OP_MINUS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-$x
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: VALUE_SCALAR
op: OP_MINUS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
\1
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_REFERENCE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
\$a
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_REFERENCE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
~12
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 12
op: OP_BIT_NOT
EOE
