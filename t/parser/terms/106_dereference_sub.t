#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

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
  sigil: '&'
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
  sigil: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
&print($a, $b);
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: $
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: $
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: print
  sigil: '&'
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
    sigil: $
  op: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
&$print($a);
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: $
context: CXT_VOID
function: !parsetree:Dereference
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: print
    sigil: $
  op: '&'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
&{&print}($a);
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: $
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
          sigil: '&'
  op: '&'
EOE
