#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
+12
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 12
op: +
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-12
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 12
op: -
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-( 1 )
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Parentheses
  context: CXT_SCALAR
  left: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  op: ()
op: -
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-$x
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: $
op: -
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
\1
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: \
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
\$a
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: $
op: \
EOE
