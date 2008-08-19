#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined $a;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
context: CXT_VOID
function: defined
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined &foo;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SUB
context: CXT_VOID
function: defined
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined &{$foo;};
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Dereference
    context: CXT_LIST
    left: !parsetree:Block
      lines:
        - !parsetree:Symbol
          context: CXT_SCALAR
          name: foo
          sigil: VALUE_SCALAR
    op: VALUE_SUB
context: CXT_VOID
function: defined
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
defined $a ? $b : $c;
EOP
--- !parsetree:Ternary
condition: !parsetree:Builtin
  arguments:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: VALUE_SCALAR
  context: CXT_SCALAR
  function: defined
context: CXT_VOID
iffalse: !parsetree:Symbol
  context: CXT_VOID
  name: c
  sigil: VALUE_SCALAR
iftrue: !parsetree:Symbol
  context: CXT_VOID
  name: b
  sigil: VALUE_SCALAR
EOE
