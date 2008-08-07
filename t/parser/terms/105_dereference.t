#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$$a
EOP
--- !parsetree:Dereference
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: $
op: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${$a . $b}
EOP
--- !parsetree:Dereference
context: CXT_VOID
left: !parsetree:Block
  lines:
    - !parsetree:BinOp
      context: CXT_SCALAR
      left: !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: $
      op: .
      right: !parsetree:Symbol
        context: CXT_SCALAR
        name: b
        sigil: $
op: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$$a = 1;
EOP
--- !parsetree:BinOp
context: 2
left: !parsetree:Dereference
  context: CXT_SCALAR|CXT_LVALUE|CXT_VIVIFY
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: $
  op: $
op: =
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${$a;} = 1;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Dereference
  context: CXT_SCALAR|CXT_LVALUE|CXT_VIVIFY
  left: !parsetree:Block
    lines:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: $
  op: $
op: =
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
%$a
EOP
--- !parsetree:Dereference
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: $
op: '%'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
*$a
EOP
--- !parsetree:Dereference
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: $
op: '*'
EOE
