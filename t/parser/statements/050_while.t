#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 4;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
while( $a > 2 ) {
    1;
}
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:Block
  lines:
    - !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
block_type: while
condition: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  op: OP_NUM_GT
  right: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
continue: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
until( $a < 2 ) {
    1;
}
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:Block
  lines:
    - !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
block_type: until
condition: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  op: OP_NUM_LT
  right: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
continue: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
while( $a > 2 ) {
    1;
} continue {
    2;
}
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:Block
  lines:
    - !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 1
block_type: while
condition: !parsetree:BinOp
  context: CXT_SCALAR
  left: !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  op: OP_NUM_GT
  right: !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_NUMBER|NUM_INTEGER
    value: 2
continue: !parsetree:Block
  lines:
    - !parsetree:Constant
      context: CXT_VOID
      flags: CONST_NUMBER|NUM_INTEGER
      value: 2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
while( my $x ) {
    $x;
} continue {
    $x;
}
$x
EOP
--- !parsetree:ConditionalLoop
block: !parsetree:Block
  lines:
    - !parsetree:LexicalSymbol
      context: CXT_VOID
      level: 0
      name: x
      sigil: VALUE_SCALAR
block_type: while
condition: !parsetree:LexicalDeclaration
  context: CXT_SCALAR
  flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
  name: x
  sigil: VALUE_SCALAR
continue: !parsetree:Block
  lines:
    - !parsetree:LexicalSymbol
      context: CXT_VOID
      level: 0
      name: x
      sigil: VALUE_SCALAR
--- !parsetree:Symbol
context: CXT_VOID
name: x
sigil: VALUE_SCALAR
EOE
