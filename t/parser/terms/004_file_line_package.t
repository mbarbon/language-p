#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
__LINE__.
__LINE__;
__LINE__;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 1
op: .
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
  value: 2
--- !parsetree:Number
flags: NUM_INTEGER
type: number
value: 3
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
# line 12 "moo.pm"
__FILE__;
__LINE__;
__PACKAGE__;
EOP
--- !parsetree:Constant
type: string
value: moo.pm
--- !parsetree:Number
flags: NUM_INTEGER
type: number
value: 13
--- !parsetree:Constant
type: string
value: main
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package foo::moo::boo;
__PACKAGE__;
package main;
__PACKAGE__;
EOP
--- !parsetree:Package
name: foo::moo::boo
--- !parsetree:Constant
type: string
value: foo::moo::boo
--- !parsetree:Package
name: main
--- !parsetree:Constant
type: string
value: main
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );

#line 4

__LINE__
EOP
--- !parsetree:Number
flags: NUM_INTEGER
type: number
value: 5
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
 #line 4

__LINE__
EOP
--- !parsetree:Number
flags: NUM_INTEGER
type: number
value: 3
EOE
