#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 < 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: <
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 > 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: '>'
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 >= 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: '>='
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 <= 2
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: <=
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
EOE
