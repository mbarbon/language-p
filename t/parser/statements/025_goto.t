#!/usr/bin/perl -w

use t::lib::TestParser tests => 12;
use Test::More import => [ qw(is) ];

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
goto &foo;
EOP
--- !parsetree:Jump
left: !parsetree:UnOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_SUB
  op: OP_REFERENCE
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
prototype: ~
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
is( $tree->[3]->get_attribute( 'target' ), $tree->[2] );
# in sub
my $lines = $tree->[0]->lines;
is( @$lines, 4 );
is( $lines->[1]->get_attribute( 'target' ), undef );
is( $lines->[2]->get_attribute( 'target' ), $lines->[3] );
