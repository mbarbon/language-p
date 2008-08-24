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
expressions:
  - !parsetree:Constant
    flags: CONST_STRING
    value: foo
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
foo::x => 1
EOP
--- !parsetree:List
expressions:
  - !parsetree:Constant
    flags: CONST_STRING
    value: foo::x
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo::q;
foo::q => 1
EOP
--- !parsetree:SubroutineDeclaration
name: foo::q
--- !parsetree:List
expressions:
  - !parsetree:FunctionCall
    arguments: ~
    context: CXT_VOID
    function: !parsetree:Symbol
      context: CXT_SCALAR
      name: foo::q
      sigil: VALUE_SUB
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
s => 1
EOP
--- !parsetree:List
expressions:
  - !parsetree:Constant
    flags: CONST_STRING
    value: s
  - !parsetree:Constant
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
          flags: CONST_NUMBER|NUM_INTEGER
          value: 2
    block_type: if
    condition: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
--- !parsetree:List
expressions:
  - !parsetree:Constant
    flags: CONST_STRING
    value: elsif
  - !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
EOE
