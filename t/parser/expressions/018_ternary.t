#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 ? 2 : 3
EOP
--- !parsetree:Ternary
condition: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
context: CXT_VOID
iffalse: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 3
iftrue: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a = 1 ? 2 : 3
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: a
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Ternary
  condition: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  context: CXT_SCALAR
  iffalse: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 3
  iftrue: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a = 1 < 2 ? 2 + 3 : 3 + 4
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: a
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Ternary
  condition: !parsetree:BinOp
    context: CXT_SCALAR
    left: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    op: OP_NUM_LT
    right: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
  context: CXT_SCALAR
  iffalse: !parsetree:BinOp
    context: CXT_SCALAR
    left: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 3
    op: OP_ADD
    right: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 4
  iftrue: !parsetree:BinOp
    context: CXT_SCALAR
    left: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
    op: OP_ADD
    right: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 3
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x ? $a = 1 : $b = 2;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Ternary
  condition: !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_SCALAR
  context: CXT_SCALAR|CXT_LVALUE
  iffalse: !parsetree:Symbol
    context: CXT_SCALAR|CXT_LVALUE
    name: b
    sigil: VALUE_SCALAR
  iftrue: !parsetree:BinOp
    context: CXT_SCALAR|CXT_LVALUE
    left: !parsetree:Symbol
      context: CXT_SCALAR|CXT_LVALUE
      name: a
      sigil: VALUE_SCALAR
    op: OP_ASSIGN
    right: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
op: OP_ASSIGN
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x ? $a :
$y ? $b :
     $c;
EOP
--- !parsetree:Ternary
condition: !parsetree:Symbol
  context: 4
  name: x
  sigil: 1
context: 2
iffalse: !parsetree:Ternary
  condition: !parsetree:Symbol
    context: 4
    name: y
    sigil: 1
  context: 2
  iffalse: !parsetree:Symbol
    context: 2
    name: c
    sigil: 1
  iftrue: !parsetree:Symbol
    context: 2
    name: b
    sigil: 1
iftrue: !parsetree:Symbol
  context: 2
  name: a
  sigil: 1
EOE
