#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
FOO:
EOP
--- !parsetree:Empty
label: FOO
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
FOO:;
EOP
--- !parsetree:Empty
label: FOO
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
_FOO_:;
1
EOP
--- !parsetree:Empty
label: _FOO_
--- !parsetree:Constant
flags: CONST_NUMBER|NUM_INTEGER
value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
_FOO_: 1
EOP
--- !parsetree:Constant
flags: CONST_NUMBER|NUM_INTEGER
label: _FOO_
value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
LOOP: foreach my $i ( 1 .. 7 ) {
    print 42
}
EOP
--- !parsetree:Foreach
block: !parsetree:Block
  lines:
    - !parsetree:BuiltinIndirect
      arguments:
        - !parsetree:Constant
          flags: CONST_NUMBER|NUM_INTEGER
          value: 42
      context: CXT_VOID
      function: OP_PRINT
      indirect: ~
continue: ~
expression: !parsetree:BinOp
  context: CXT_LIST
  left: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 1
  op: OP_DOT_DOT
  right: !parsetree:Constant
    flags: CONST_NUMBER|NUM_INTEGER
    value: 7
label: LOOP
variable: !parsetree:LexicalDeclaration
  context: CXT_SCALAR
  flags: DECLARATION_MY
  name: i
  sigil: VALUE_SCALAR
EOE
