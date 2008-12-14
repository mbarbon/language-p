#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 13;

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
  sigil: VALUE_SCALAR
op: OP_DEREFERENCE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$$$$a
EOP
--- !parsetree:Dereference
context: CXT_VOID
left: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Dereference
    context: CXT_SCALAR
    left: !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: VALUE_SCALAR
    op: OP_DEREFERENCE_SCALAR
  op: OP_DEREFERENCE_SCALAR
op: OP_DEREFERENCE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$$${a}
EOP
--- !parsetree:Dereference
context: CXT_VOID
left: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  op: OP_DEREFERENCE_SCALAR
op: OP_DEREFERENCE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$$$::a
EOP
--- !parsetree:Dereference
context: CXT_VOID
left: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  op: OP_DEREFERENCE_SCALAR
op: OP_DEREFERENCE_SCALAR
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
        sigil: VALUE_SCALAR
      op: OP_CONCATENATE
      right: !parsetree:Symbol
        context: CXT_SCALAR
        name: b
        sigil: VALUE_SCALAR
op: OP_DEREFERENCE_SCALAR
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
    sigil: VALUE_SCALAR
  op: OP_DEREFERENCE_SCALAR
op: OP_ASSIGN
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
        sigil: VALUE_SCALAR
  op: OP_DEREFERENCE_SCALAR
op: OP_ASSIGN
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
  sigil: VALUE_SCALAR
op: OP_DEREFERENCE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
*$a
EOP
--- !parsetree:Dereference
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_DEREFERENCE_GLOB
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
  sigil: VALUE_HASH
type: VALUE_HASH
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
    sigil: VALUE_HASH
  type: VALUE_HASH
type: VALUE_ARRAY
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
    sigil: VALUE_HASH
  type: VALUE_HASH
type: VALUE_ARRAY
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
      sigil: VALUE_SCALAR
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: foo
      sigil: VALUE_HASH
    type: VALUE_HASH
EOE
