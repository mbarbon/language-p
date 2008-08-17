#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 10;

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
context: CXT_VOID
left: !parsetree:Dereference
  context: CXT_SCALAR|CXT_LVALUE|CXT_VIVIFY
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: $
  op: $
op: =
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
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
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
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

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${foo{2}}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: foo
  sigil: '%'
type: '{'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${foo{2}[1]}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 1
subscript: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
subscripted: !parsetree:Subscript
  context: CXT_SCALAR|CXT_VIVIFY
  reference: 0
  subscript: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  subscripted: !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: '%'
  type: '{'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${foo{2}}[1]
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 1
subscript: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
subscripted: !parsetree:Subscript
  context: CXT_SCALAR|CXT_VIVIFY
  reference: 0
  subscript: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  subscripted: !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: '%'
  type: '{'
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"${foo{$BAR}}"
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Subscript
    context: CXT_SCALAR
    reference: 0
    subscript: !parsetree:Symbol
      context: CXT_SCALAR
      name: BAR
      sigil: $
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: foo
      sigil: '%'
    type: '{'
EOE
