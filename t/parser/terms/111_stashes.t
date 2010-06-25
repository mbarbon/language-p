#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 6;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
%::
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: ''
sigil: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
%main::
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: ''
sigil: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
%a::b::
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: 'a::b::'
sigil: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$::{a}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: a
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: ''
  sigil: VALUE_HASH
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$main::{a}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: a
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: ''
  sigil: VALUE_HASH
type: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a::b::{a}
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 0
subscript: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: a
subscripted: !parsetree:Symbol
  context: CXT_LIST
  name: 'a::b::'
  sigil: VALUE_HASH
type: VALUE_HASH
EOE
