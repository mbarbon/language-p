#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 11;

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
  context: CXT_SCALAR
  expressions:
    - !parsetree:Constant
      context: CXT_VOID
      flags: CONST_STRING
      value: FOO
    - !parsetree:Constant
      context: CXT_SCALAR
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

# check goto targets are linked correctly
my $tree = parse_string( <<EOP );
BAR:;
FOO:;
FOO:
sub moo {
    goto FOO;
    goto BAR;
    BAR:;
}
goto FOO;
EOP

is( @$tree, 4 );
# in main
is( $tree->[3]->get_attribute( 'target' ), $tree->[1] );
# in sub
my $lines = $tree->[2]->lines;
is( @$lines, 3 );
is( $lines->[0]->get_attribute( 'target' ), undef );
is( $lines->[1]->get_attribute( 'target' ), $lines->[2] );
