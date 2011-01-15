#!/usr/bin/perl -w

use t::lib::TestParser tests => 2;
use Language::P::Constants qw(VALUE_SUB);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub lc;
lc
EOP
--- !parsetree:SubroutineDeclaration
name: lc
prototype: ~
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
lc
EOP
--- !parsetree:FunctionCall
arguments: ~
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: lc
  sigil: VALUE_SUB
EOE
