#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined $a;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_DEFINED
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined &foo;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SUB
context: CXT_VOID
function: OP_DEFINED
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined &{$foo;};
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Dereference
    context: CXT_SCALAR
    left: !parsetree:Block
      lines:
        - !parsetree:Symbol
          context: CXT_SCALAR
          name: foo
          sigil: VALUE_SCALAR
    op: OP_DEREFERENCE_SUB
context: CXT_VOID
function: OP_DEFINED
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined $a ? $b : $c;
EOP
--- !parsetree:Ternary
condition: !parsetree:Builtin
  arguments:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: VALUE_SCALAR
  context: CXT_SCALAR
  function: OP_DEFINED
context: CXT_VOID
iffalse: !parsetree:Symbol
  context: CXT_VOID
  name: c
  sigil: VALUE_SCALAR
iftrue: !parsetree:Symbol
  context: CXT_VOID
  name: b
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
exists $x{1}
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Subscript
    context: CXT_LIST
    reference: 0
    subscript: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: x
      sigil: VALUE_HASH
    type: VALUE_HASH
context: CXT_VOID
function: OP_EXISTS
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
exists $x{1} + 1
EOP
--- !p:Exception
file: '<string>'
line: 1
message: exists argument is not a HASH or ARRAY element or a subroutine
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
exists &foo
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SUB
context: CXT_VOID
function: OP_EXISTS
EOE
