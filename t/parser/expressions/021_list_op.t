#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
x( 1, 2 );
EOP
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 1
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 2
context: CXT_VOID
function: x
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x;

x 1, 2;
EOP
--- !parsetree:SubroutineDeclaration
name: x
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 1
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 2
context: CXT_VOID
function: x
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x { };

x 1, 2;
EOP
--- !parsetree:Subroutine
lines: []
name: x
--- !parsetree:FunctionCall
arguments:
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 1
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 2
context: CXT_VOID
function: x
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print, 1,
print, 1;
EOP
--- !parsetree:List
expressions:
  - !parsetree:Print
    arguments: ~
    context: CXT_VOID
    filehandle: ~
    function: print
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 1
  - !parsetree:Print
    arguments: ~
    context: CXT_VOID
    filehandle: ~
    function: print
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print, 1,
print => 1;
EOP
--- !parsetree:List
expressions:
  - !parsetree:Print
    arguments: ~
    context: CXT_VOID
    filehandle: ~
    function: print
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 1
  - !parsetree:Constant
    type: string
    value: print
  - !parsetree:Number
    flags: NUM_INTEGER
    type: number
    value: 1
EOE
