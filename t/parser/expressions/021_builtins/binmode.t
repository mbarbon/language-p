#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
binmode FOO, ':utf8';
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FOO
    sigil: VALUE_GLOB
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: :utf8
context: CXT_VOID
function: OP_BINMODE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
binmode $foo
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_BINMODE
EOE
