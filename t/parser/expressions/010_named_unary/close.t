#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
close FOO
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FOO
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_CLOSE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
close @foo
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_CLOSE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
close
EOP
--- !parsetree:Overridable
arguments: ~
context: CXT_VOID
function: OP_CLOSE
EOE
