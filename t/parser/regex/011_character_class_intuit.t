#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$x[1]/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: $
op: =~
right: !parsetree:InterpolatedPattern
  flags: ~
  op: m
  string: !parsetree:QuotedString
    components:
      - !parsetree:Subscript
        context: CXT_SCALAR
        reference: 0
        subscript: !parsetree:Number
          flags: NUM_INTEGER
          type: number
          value: 1
        subscripted: !parsetree:Symbol
          context: CXT_LIST
          name: x
          sigil: '@'
        type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/$x[a]/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: $
op: =~
right: !parsetree:InterpolatedPattern
  flags: ~
  op: m
  string: !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: x
        sigil: $
      - !parsetree:Constant
        type: string
        value: '[a]'
EOE
