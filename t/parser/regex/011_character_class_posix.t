#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[[:alpha:]]/;
EOP
--- !parsetree:BinOp
context: 2
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: _
  sigil: VALUE_SCALAR
op: OP_MATCH
right: !parsetree:Pattern
  components:
    - !parsetree:RXClass
      elements:
        - !parsetree:RXPosixClass
          type: alpha
  flags: 0
  op: OP_QL_M
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
/[[:invalid:]]/;
EOP
--- !p:Exception
file: ~
line: 1
message: Invalid POSIX character class 'invalid'
EOE
