#!/usr/bin/perl -w

use t::lib::TestParser tests => 5;
use Language::P::Constants qw(VALUE_SUB);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
CORE::lc
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_LC
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE', [ [ 'lc' => VALUE_SUB ] ] );
CORE::lc
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: _
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_LC
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE', [ [ 'lc' => VALUE_SUB ] ] );
CORE::foo
EOP
--- !p:Exception
file: '<string>'
line: 1
message: CORE::foo is not a keyword
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE', [ [ 'lc' => VALUE_SUB ] ] );
$a CORE::and $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_LOG_AND
right: !parsetree:Symbol
  context: CXT_VOID
  name: b
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE', [ [ 'lc' => VALUE_SUB ] ] );
$a CORE::x $b
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: a
  sigil: VALUE_SCALAR
op: OP_REPEAT
right: !parsetree:Symbol
  context: CXT_SCALAR
  name: b
  sigil: VALUE_SCALAR
EOE
