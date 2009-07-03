#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 8;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo->moo;
EOP
--- !parsetree:MethodCall
arguments: ~
context: CXT_VOID
indirect: 0
invocant: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: foo
method: moo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo->$moo;
EOP
--- !parsetree:MethodCall
arguments: ~
context: CXT_VOID
indirect: 1
invocant: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: foo
method: !parsetree:Symbol
  context: CXT_SCALAR
  name: moo
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo->moo( 1, 2 );
EOP
--- !parsetree:MethodCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
indirect: 0
invocant: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: foo
method: moo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo->$moo( 1, 2 );
EOP
--- !parsetree:MethodCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
indirect: 1
invocant: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: foo
method: !parsetree:Symbol
  context: CXT_SCALAR
  name: moo
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x->[1]->$moo->moo()->[2]->boo($a);
EOP
--- !parsetree:MethodCall
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
context: CXT_VOID
indirect: 0
invocant: !parsetree:Subscript
  context: CXT_SCALAR
  reference: 1
  subscript: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
  subscripted: !parsetree:MethodCall
    arguments: ~
    context: CXT_SCALAR|CXT_VIVIFY
    indirect: 0
    invocant: !parsetree:MethodCall
      arguments: ~
      context: CXT_SCALAR
      indirect: 1
      invocant: !parsetree:Subscript
        context: CXT_SCALAR
        reference: 1
        subscript: !parsetree:Constant
          context: CXT_SCALAR
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
        subscripted: !parsetree:Symbol
          context: CXT_SCALAR|CXT_VIVIFY
          name: x
          sigil: VALUE_SCALAR
        type: VALUE_ARRAY
      method: !parsetree:Symbol
        context: CXT_SCALAR
        name: moo
        sigil: VALUE_SCALAR
    method: moo
  type: VALUE_ARRAY
method: boo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo->moo::boo( 1, 2 );
EOP
--- !parsetree:MethodCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
indirect: 0
invocant: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: foo
method: moo::boo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$foo->$moo::boo( 1, 2 );
EOP
--- !parsetree:MethodCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
indirect: 1
invocant: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SCALAR
method: !parsetree:Symbol
  context: CXT_SCALAR
  name: moo::boo
  sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print Foo->moo( 1, 2 );
EOP
--- !parsetree:BuiltinIndirect
arguments:
  - !parsetree:MethodCall
    arguments:
      - !parsetree:Constant
        context: CXT_LIST
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      - !parsetree:Constant
        context: 8
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
    context: CXT_LIST
    indirect: 0
    invocant: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING
      value: Foo
    method: moo
context: CXT_VOID
function: OP_PRINT
indirect: ~
EOE
