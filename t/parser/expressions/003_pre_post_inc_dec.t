#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 8;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
++$a
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: a
  sigil: VALUE_SCALAR
op: OP_PREINC
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a++
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: a
  sigil: VALUE_SCALAR
op: OP_POSTINC
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
--$a
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: a
  sigil: VALUE_SCALAR
op: OP_PREDEC
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a--
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: a
  sigil: VALUE_SCALAR
op: OP_POSTDEC
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a-- + $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:UnOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR|CXT_LVALUE
    name: a
    sigil: VALUE_SCALAR
  op: OP_POSTDEC
op: OP_ADD
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print ++$a
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:UnOp
    context: CXT_LIST
    left: !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: a
      sigil: VALUE_SCALAR
    op: OP_PREINC
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print $b++
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:UnOp
    context: CXT_LIST
    left: !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: b
      sigil: VALUE_SCALAR
    op: OP_POSTINC
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
-$a++
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:UnOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR|CXT_LVALUE
    name: a
    sigil: VALUE_SCALAR
  op: OP_POSTINC
op: OP_MINUS
EOE
