#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
goto FOO;
EOP
--- !parsetree:Jump
left: FOO
op: OP_GOTO
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
goto $foo;
EOP
--- !parsetree:Jump
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_SCALAR
op: OP_GOTO
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
goto "FOO";
EOP
--- !parsetree:Jump
left: FOO
op: OP_GOTO
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
goto ("FOO");
EOP
--- !parsetree:Jump
left: FOO
op: OP_GOTO
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
goto ("FOO", "X");
EOP
--- !parsetree:Jump
left: !parsetree:List
  expressions:
    - !parsetree:Constant
      flags: CONST_STRING
      value: FOO
    - !parsetree:Constant
      flags: CONST_STRING
      value: X
op: OP_GOTO
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo;
goto foo;
EOP
--- !parsetree:SubroutineDeclaration
name: foo
--- !parsetree:Jump
left: foo
op: OP_GOTO
EOE
