#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
EOP
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: x
warnings: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
$!;
EOP
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: x
warnings: ~
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
--- !parsetree:BareBlock
continue: ~
lines:
  - !parsetree:LexicalState
    changed: CHANGED_PACKAGE
    hints: 0
    package: x
    warnings: ~
  - !parsetree:Symbol
    context: CXT_VOID
    name: x::x
    sigil: VALUE_SCALAR
  - !parsetree:Symbol
    context: CXT_VOID
    name: w
    sigil: VALUE_SCALAR
  - !parsetree:LexicalState
    changed: CHANGED_PACKAGE
    hints: 0
    package: z
    warnings: ~
--- !parsetree:Symbol
context: CXT_VOID
name: x
sigil: VALUE_SCALAR
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: y
warnings: ~
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
prototype: ~
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: x
warnings: ~
--- !parsetree:SubroutineDeclaration
name: x::z
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x;
package y;
::x 1;
main::x 1
EOP
--- !parsetree:SubroutineDeclaration
name: x
prototype: ~
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: y
warnings: ~
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
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
    context: CXT_LIST
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
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: main
warnings: ~
--- !parsetree:SubroutineDeclaration
name: xm
prototype: ~
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: w
warnings: ~
--- !parsetree:SubroutineDeclaration
name: w::xw
prototype: ~
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
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
    context: CXT_LIST
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
    context: CXT_LIST
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
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: w::xw
  sigil: VALUE_SUB
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: main
warnings: ~
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
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
    context: CXT_LIST
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
    context: CXT_LIST
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
    context: CXT_LIST
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
prototype: ~
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: y
warnings: ~
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: y::x
  sigil: VALUE_SUB
--- !parsetree:SubroutineDeclaration
name: w
prototype: ~
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: main
warnings: ~
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
context: CXT_VOID
function: !parsetree:Symbol
  context: CXT_SCALAR
  name: w
  sigil: VALUE_SUB
EOE
