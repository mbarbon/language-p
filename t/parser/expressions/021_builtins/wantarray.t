#!/usr/bin/perl -w

use t::lib::TestParser tests => 1;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
wantarray
EOP
--- !parsetree:Overridable
arguments: ~
context: CXT_VOID
function: OP_WANTARRAY
EOE
