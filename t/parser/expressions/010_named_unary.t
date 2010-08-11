#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined $a ? $b : $c;
EOP
--- !parsetree:Ternary
condition: !parsetree:Builtin
  arguments:
    - !parsetree:Symbol
      context: CXT_SCALAR|CXT_NOCREATE
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
