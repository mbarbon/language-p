#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[abc]/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: $
op: =~
right: !parsetree:Pattern
  components:
    - !parsetree:RXClass
      elements:
        - a
        - b
        - c
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[a-q]/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: $
op: =~
right: !parsetree:Pattern
  components:
    - !parsetree:RXClass
      elements:
        - !parsetree:RXRange
          end: q
          start: a
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[a-]/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: $
op: =~
right: !parsetree:Pattern
  components:
    - !parsetree:RXClass
      elements:
        - a
        - -
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[a-\w]/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: $
op: =~
right: !parsetree:Pattern
  components:
    - !parsetree:RXClass
      elements:
        - a
        - -
        - !parsetree:RXSpecialClass
          type: WORDS
  flags: ~
  op: m
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[[\]]/;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: $
op: =~
right: !parsetree:Pattern
  components:
    - !parsetree:RXClass
      elements:
        - '['
        - ']'
  flags: ~
  op: m
EOE
