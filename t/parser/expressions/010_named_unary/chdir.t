#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
chdir FOO
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FOO
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_CHDIR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
chdir @foo
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_CHDIR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
chdir
EOP
--- !parsetree:Overridable
arguments: ~
context: CXT_VOID
function: OP_CHDIR
EOE
