#!/usr/bin/perl -w

use t::lib::TestParser tests => 4;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined $a;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR|CXT_NOCREATE
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
    context: CXT_SCALAR|CXT_NOCREATE
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
    context: CXT_SCALAR|CXT_NOCREATE
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
defined $a[1]
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Subscript
    context: CXT_SCALAR|CXT_NOCREATE
    reference: 0
    subscript: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    subscripted: !parsetree:Symbol
      context: CXT_LIST
      name: a
      sigil: VALUE_ARRAY
    type: VALUE_ARRAY
context: CXT_VOID
function: OP_DEFINED
EOE
