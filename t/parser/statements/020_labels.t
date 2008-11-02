#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
FOO:
EOP
--- !parsetree:Label
name: FOO
statement: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
FOO:;
EOP
--- !parsetree:Label
name: FOO
statement: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
_FOO_:;
1
EOP
--- !parsetree:Label
name: _FOO_
statement: ~
--- !parsetree:Constant
flags: CONST_NUMBER|NUM_INTEGER
value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
_FOO_: 1
EOP
--- !parsetree:Label
name: _FOO_
statement: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
LOOP: foreach my $i ( 1 .. 7 ) {
    print 42
}
EOP
--- !parsetree:Label
name: LOOP
statement: !parsetree:Foreach
  block: !parsetree:Block
    lines:
      - !parsetree:BuiltinIndirect
        arguments:
          - !parsetree:Constant
            flags: CONST_NUMBER|NUM_INTEGER
            value: 42
        context: CXT_VOID
        function: print
        indirect: ~
  expression: !parsetree:BinOp
    context: CXT_LIST
    left: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
    op: OP_DOT_DOT
    right: !parsetree:Constant
      flags: CONST_NUMBER|NUM_INTEGER
      value: 7
  variable: !parsetree:LexicalDeclaration
    context: CXT_SCALAR
    flags: DECLARATION_MY
    name: i
    sigil: VALUE_SCALAR
EOE
