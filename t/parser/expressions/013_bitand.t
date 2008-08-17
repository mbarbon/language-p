#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1 & foo()
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
op: '&'
right: !parsetree:FunctionCall
  arguments: ~
  context: CXT_SCALAR
  function: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: '&'
EOE
