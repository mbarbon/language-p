#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
glob @test
EOP
--- !parsetree:Glob
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: test
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
glob
EOP
--- !parsetree:Glob
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_GLOB
EOE
