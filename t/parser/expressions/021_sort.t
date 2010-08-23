#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 5;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sort @foo, @boo
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_LIST
    name: boo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SORT
indirect: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sort { @foo } @foo, @boo
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_LIST
    name: boo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SORT
indirect: !parsetree:Block
  lines:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: foo
      sigil: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sort $foo @foo, @boo
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_LIST
    name: boo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SORT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sort foo @foo, @boo
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Symbol
    context: CXT_LIST
    name: foo
    sigil: VALUE_ARRAY
  - !parsetree:Symbol
    context: CXT_LIST
    name: boo
    sigil: VALUE_ARRAY
context: CXT_VOID
function: OP_SORT
indirect: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sort keys %foo
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:Overridable
    arguments:
      - !parsetree:Symbol
        context: CXT_LIST
        name: foo
        sigil: VALUE_HASH
    context: CXT_LIST
    function: OP_KEYS
context: CXT_VOID
function: OP_SORT
indirect: ~
EOE
