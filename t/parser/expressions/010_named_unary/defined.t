#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

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
