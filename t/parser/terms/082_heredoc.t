#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print <<EOT
test
EOT
EOP
--- !parsetree:Print
arguments:
  - !parsetree:Constant
    flags: CONST_STRING
    value: "test\n"
context: CXT_VOID
filehandle: ~
function: print
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print <<EOT
$a
EOT
EOP
--- !parsetree:Print
arguments:
  - !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        flags: CONST_STRING
        value: "\n"
context: CXT_VOID
filehandle: ~
function: print
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print << "EOT"
$a
EOT
EOP
--- !parsetree:Print
arguments:
  - !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: a
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        flags: CONST_STRING
        value: "\n"
context: CXT_VOID
filehandle: ~
function: print
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print << 'EOT'
$a
EOT
EOP
--- !parsetree:Print
arguments:
  - !parsetree:Constant
    flags: CONST_STRING
    value: "$a\n"
context: CXT_VOID
filehandle: ~
function: print
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print << `EOT`
ls
EOT
EOP
--- !parsetree:Print
arguments:
  - !parsetree:UnOp
    context: CXT_LIST
    left: !parsetree:Constant
      flags: CONST_STRING
      value: "ls\n"
    op: backtick
context: CXT_VOID
filehandle: ~
function: print
EOE
