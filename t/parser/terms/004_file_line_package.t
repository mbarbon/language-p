#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 8;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
__LINE__.
__LINE__;
__LINE__;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
op: OP_CONCATENATE
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_INTEGER
value: 3
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
# line 12 "moo.pm"
__FILE__;
__LINE__;
__PACKAGE__;
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: moo.pm
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_INTEGER
value: 13
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: main
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package foo::moo::boo;
__PACKAGE__;
package main;
__PACKAGE__;
EOP
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: foo::moo::boo
warnings: ~
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: foo::moo::boo
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: main
warnings: ~
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: main
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );

#line 4

__LINE__
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_INTEGER
value: 5
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
 #line 4

__LINE__
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_INTEGER
value: 3
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
# a line
__LINE__
=cut

 =pod
=pod
=cut
 =
__LINE__;
=tail


EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR|CXT_LVALUE
  flags: CONST_NUMBER|NUM_INTEGER
  value: 2
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 9
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<<EOT; __LINE__;


EOT
__LINE__
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: "\n\n"
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_INTEGER
value: 1
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_INTEGER
value: 5
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qq{


};
__LINE__
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: "\n\n\n"
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_INTEGER
value: 5
EOE
