#!/usr/bin/perl -w

use t::lib::TestParser tests => 5;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
chop $a
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_CHOP
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
chop @a
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_CHOP
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
chop %a
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_HASH
context: CXT_VOID
function: OP_CHOP
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
chop( $a, $b )
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_CHOP
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
chop
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_CHOP
EOE
