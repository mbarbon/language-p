#!/usr/bin/perl -w

use t::lib::TestParser tests => 5;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
open FOO
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FOO
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_OPEN
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
open FOO, '>/tmp/foo';
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FOO
    sigil: VALUE_GLOB
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: '>/tmp/foo'
context: CXT_VOID
function: OP_OPEN
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
open FOO, '>', '/tmp/foo';
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FOO
    sigil: VALUE_GLOB
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: '>'
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_STRING
    value: /tmp/foo
context: CXT_VOID
function: OP_OPEN
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
open FOO, '-|', '/bin/cat', '/dev/urandom';
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: FOO
    sigil: VALUE_GLOB
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: '-|'
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_STRING
    value: /bin/cat
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_STRING
    value: /dev/urandom
context: CXT_VOID
function: OP_OPEN
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
open my $foo, '>', '/tmp/foo';
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:LexicalDeclaration
    context: CXT_SCALAR
    flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
    name: foo
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: '>'
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_STRING
    value: /tmp/foo
context: CXT_VOID
function: OP_OPEN
EOE
