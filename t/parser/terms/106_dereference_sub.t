#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
&print;
EOP
--- !parsetree:SpecialFunctionCall
arguments: ~
context: CXT_VOID
flags: FLAG_IMPLICITARGUMENTS
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: print
  sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
&print();
EOP
--- !parsetree:FunctionCall
arguments: ~
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: print
  sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
&print($a, $b);
EOP
--- !parsetree:FunctionCall
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
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: print
  sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
&$print;
EOP
--- !parsetree:SpecialFunctionCall
arguments: ~
context: CXT_VOID
flags: FLAG_IMPLICITARGUMENTS
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: print
    sigil: VALUE_SCALAR
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
&$print($a);
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
context: CXT_VOID
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: print
    sigil: VALUE_SCALAR
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
&{&print}($a);
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
context: CXT_VOID
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Block
    lines:
      - !parsetree:SpecialFunctionCall
        arguments: ~
        context: CXT_SCALAR
        flags: FLAG_IMPLICITARGUMENTS
        function: !parsetree:Symbol
          context: CXT_SCALAR
          name: print
          sigil: VALUE_SUB
  op: OP_DEREFERENCE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo->();
EOP
--- !parsetree:FunctionCall
arguments: ~
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SUB
EOE
