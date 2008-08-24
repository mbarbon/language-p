#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
[]
EOP
--- !parsetree:ReferenceConstructor
expression: ~
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
[$a, 1 + 2]
EOP
--- !parsetree:ReferenceConstructor
expression: !parsetree:List
  expressions:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: VALUE_SCALAR
    - !parsetree:BinOp
      context: CXT_LIST
      left: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      op: OP_ADD
      right: !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{}
EOP
--- !parsetree:ReferenceConstructor
expression: ~
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{q => 1}
EOP
--- !parsetree:ReferenceConstructor
expression: !parsetree:List
  expressions:
    - !parsetree:Constant
      flags: CONST_STRING
      value: q
    - !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
{1}
EOP
--- !parsetree:Block
lines:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE
