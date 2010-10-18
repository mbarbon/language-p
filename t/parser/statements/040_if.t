#!/usr/bin/perl -w

use strict;
use t::lib::TestParser tests => 5;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
if( $a > 2 ) {
    1;
}
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
          value: 1
    block_type: if
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
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
unless( $a > 2 ) {
    1;
}
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
          value: 1
    block_type: unless
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
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
if( $a < 2 ) {
    1;
} else {
    3;
}
EOP
--- !parsetree:Conditional
iffalse: !parsetree:ConditionalBlock
  block: !parsetree:Block
    lines:
      - !parsetree:Constant
        context: CXT_VOID
        flags: CONST_NUMBER|NUM_INTEGER
        value: 3
  block_type: else
  condition: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          context: CXT_VOID
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
    block_type: if
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
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
if( $a < 2 ) {
    1;
} elsif( $a < 3 ) {
    2;
} else {
    3;
}
EOP
--- !parsetree:Conditional
iffalse: !parsetree:ConditionalBlock
  block: !parsetree:Block
    lines:
      - !parsetree:Constant
        context: CXT_VOID
        flags: CONST_NUMBER|NUM_INTEGER
        value: 3
  block_type: else
  condition: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          context: CXT_VOID
          flags: CONST_NUMBER|NUM_INTEGER
          value: 1
    block_type: if
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
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:Constant
          context: CXT_VOID
          flags: CONST_NUMBER|NUM_INTEGER
          value: 2
    block_type: if
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
        value: 3
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
if( my $x ) {
    $x;
} elsif( $x && my $y ) {
    $x; $y;
}
$x; $y;
EOP
--- !parsetree:Conditional
iffalse: ~
iftrues:
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:LexicalSymbol
          context: CXT_VOID
          level: 0
          name: x
          sigil: VALUE_SCALAR
    block_type: if
    condition: !parsetree:LexicalDeclaration
      context: CXT_SCALAR
      flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
      name: x
      sigil: VALUE_SCALAR
  - !parsetree:ConditionalBlock
    block: !parsetree:Block
      lines:
        - !parsetree:LexicalSymbol
          context: CXT_VOID
          level: 0
          name: x
          sigil: VALUE_SCALAR
        - !parsetree:LexicalSymbol
          context: CXT_VOID
          level: 0
          name: y
          sigil: VALUE_SCALAR
    block_type: if
    condition: !parsetree:BinOp
      context: CXT_SCALAR
      left: !parsetree:LexicalSymbol
        context: CXT_SCALAR
        level: 0
        name: x
        sigil: VALUE_SCALAR
      op: OP_LOG_AND
      right: !parsetree:LexicalDeclaration
        context: CXT_SCALAR
        flags: DECLARATION_MY|DECLARATION_CLOSED_OVER
        name: y
        sigil: VALUE_SCALAR
--- !parsetree:Symbol
context: CXT_VOID
name: x
sigil: VALUE_SCALAR
--- !parsetree:Symbol
context: CXT_VOID
name: y
sigil: VALUE_SCALAR
EOE
