#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print defined 1, 2
EOP
--- !parsetree:Print
arguments:
  - !parsetree:Builtin
    arguments:
      - !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_LIST
    function: defined
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
context: CXT_VOID
filehandle: ~
function: print
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print unlink 1, 2
EOP
--- !parsetree:Print
arguments:
  - !parsetree:Overridable
    arguments:
      - !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
      - !parsetree:Constant
        flags: CONST_NUMBER|NUM_INTEGER
        value: 2
    context: CXT_LIST
    function: unlink
context: CXT_VOID
filehandle: ~
function: print
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
open FILE, ">foo" or die "error";
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Overridable
  arguments:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: FILE
      sigil: VALUE_GLOB
    - !parsetree:Constant
      flags: CONST_STRING
      value: '>foo'
  context: CXT_SCALAR
  function: open
op: OP_LOG_OR
right: !parsetree:Overridable
  arguments:
    - !parsetree:Constant
      flags: CONST_STRING
      value: error
  context: CXT_VOID
  function: die
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print FILE $stuff;
EOP
--- !parsetree:Print
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: stuff
    sigil: VALUE_SCALAR
context: CXT_VOID
filehandle: !parsetree:Symbol
  context: CXT_SCALAR
  name: FILE
  sigil: VALUE_GLOB
function: print
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
pipe $foo, FILE
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SCALAR
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FILE
    sigil: VALUE_GLOB
context: CXT_VOID
function: pipe
EOE
