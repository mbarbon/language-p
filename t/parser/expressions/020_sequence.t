#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo(),boo();
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_VOID
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo
      sigil: VALUE_SUB
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_VOID
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: boo
      sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a->[foo(),boo()];
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 1
subscript: !parsetree:List
  context: CXT_SCALAR
  expressions:
    - !parsetree:FunctionCall
      arguments: ~
      context: CXT_VOID
      function: !parsetree:Symbol
        context: CXT_SCALAR
        name: foo
        sigil: VALUE_SUB
    - !parsetree:FunctionCall
      arguments: ~
      context: CXT_SCALAR
      function: !parsetree:Symbol
        context: CXT_SCALAR
        name: boo
        sigil: VALUE_SUB
subscripted: !parsetree:Symbol
  context: CXT_SCALAR|CXT_VIVIFY
  name: a
  sigil: VALUE_SCALAR
type: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo(foo(),boo())
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo
      sigil: VALUE_SUB
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: boo
      sigil: VALUE_SUB
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SUB
EOE
