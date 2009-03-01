#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 12;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1725272
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_INTEGER
value: 1725272
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
0b101010
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_BINARY
value: 101010
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
0xffa1345
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_HEXADECIMAL
value: ffa1345
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
0
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_INTEGER
value: 0
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
0755
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_OCTAL
value: 755
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1.2
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_FLOAT
value: 1.2
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
173.
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_FLOAT
value: 173
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
.0123
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_FLOAT
value: 0.0123
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1E7
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_FLOAT
value: 1e7
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
1e+07
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_FLOAT
value: 1e+07
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
12.7e-3
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_NUMBER|NUM_FLOAT
value: 12.7e-3
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
12..15
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 12
op: OP_DOT_DOT
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_NUMBER|NUM_INTEGER
  value: 15
EOE
