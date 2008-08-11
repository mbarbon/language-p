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
    type: string
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
        sigil: $
      - !parsetree:Constant
        type: string
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
        sigil: $
      - !parsetree:Constant
        type: string
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
    type: string
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
      type: string
      value: "ls\n"
    op: backtick
context: CXT_VOID
filehandle: ~
function: print
EOE
