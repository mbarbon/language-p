#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
split /foo/, $foo
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Pattern
    components:
      - !parsetree:RXConstant
        insensitive: 0
        value: foo
    flags: 0
    op: OP_QL_M
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_SPLIT
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
split /foo/
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Pattern
    components:
      - !parsetree:RXConstant
        insensitive: 0
        value: foo
    flags: 0
    op: OP_QL_M
context: CXT_VOID
function: OP_SPLIT
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
split
EOP
--- !parsetree:Builtin
arguments: ~
context: CXT_VOID
function: OP_SPLIT
EOE
