#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo => 1
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_STRING
    value: foo
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo::x => 1
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_STRING
    value: foo::x
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo::q;
foo::q => 1
EOP
--- !parsetree:SubroutineDeclaration
name: foo::q
prototype: ~
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_VOID
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo::q
      sigil: VALUE_SUB
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s => 1
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_STRING
    value: s
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
if( 1 ) { 2 }
elsif => 2
EOP
--- !parsetree:Conditional
iffalse: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          context: CXT_VOID
          flags: CONST_NUMBER|NUM_INTEGER
          value: 2
    block_type: if
    condition: !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_STRING
    value: elsif
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
EOE
