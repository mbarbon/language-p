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
expressions:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_VOID
    function: foo
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_VOID
    function: boo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$a->[foo(),boo()];
EOP
--- !parsetree:Subscript
context: CXT_VOID
reference: 1
subscript: !parsetree:List
  expressions:
    - !parsetree:FunctionCall
      arguments: ~
      context: CXT_VOID
      function: foo
    - !parsetree:FunctionCall
      arguments: ~
      context: CXT_SCALAR
      function: boo
subscripted: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: a
  sigil: $
type: '['
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo(foo(),boo())
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: foo
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_LIST
    function: boo
context: CXT_VOID
function: foo
EOE
