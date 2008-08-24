#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
EOP
--- !parsetree:Package
name: x
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
$!;
EOP
--- !parsetree:Package
name: x
--- !parsetree:Symbol
context: CXT_VOID
name: '!'
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x;
{
    package x;
    $x;
    $'w;
    package z
}
$x;
package y;
$x;
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: x
sigil: VALUE_SCALAR
--- !parsetree:Block
lines:
  - !parsetree:Package
    name: x
  - !parsetree:Symbol
    context: CXT_VOID
    name: x::x
    sigil: VALUE_SCALAR
  - !parsetree:Symbol
    context: CXT_VOID
    name: w
    sigil: VALUE_SCALAR
  - !parsetree:Package
    name: z
--- !parsetree:Symbol
context: CXT_VOID
name: x
sigil: VALUE_SCALAR
--- !parsetree:Package
name: y
--- !parsetree:Symbol
context: CXT_VOID
name: y::x
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub y;
package x;
sub z;
EOP
--- !parsetree:SubroutineDeclaration
name: y
--- !parsetree:Package
name: x
--- !parsetree:SubroutineDeclaration
name: x::z
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x;
package y;
::x 1;
main::x 1
EOP
--- !parsetree:SubroutineDeclaration
name: x
--- !parsetree:Package
name: y
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: VALUE_SUB
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: x
  sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package main;
sub xm;

package w;
sub xw;

main::xm 1;
::xm 1;
xw 1;
w::xw 1;

package main;

xm 1;
main::xm 1;
::xm 1;
w::xw 1;
EOP
--- !parsetree:Package
name: main
--- !parsetree:SubroutineDeclaration
name: xm
--- !parsetree:Package
name: w
--- !parsetree:SubroutineDeclaration
name: w::xw
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: xm
  sigil: VALUE_SUB
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: xm
  sigil: VALUE_SUB
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: w::xw
  sigil: VALUE_SUB
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: w::xw
  sigil: VALUE_SUB
--- !parsetree:Package
name: main
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: xm
  sigil: VALUE_SUB
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: xm
  sigil: VALUE_SUB
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: xm
  sigil: VALUE_SUB
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: w::xw
  sigil: VALUE_SUB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub y::x;
package y;
x 1;
sub main::w;
package main;
w 1;
EOP
--- !parsetree:SubroutineDeclaration
name: y::x
--- !parsetree:Package
name: y
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: y::x
  sigil: VALUE_SUB
--- !parsetree:SubroutineDeclaration
name: w
--- !parsetree:Package
name: main
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: w
  sigil: VALUE_SUB
EOE
