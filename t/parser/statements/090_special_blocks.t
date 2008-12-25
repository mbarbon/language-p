#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
BEGIN {
    1
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:Builtin
    arguments:
      - !parsetree:Constant
        context: CXT_CALLER
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_CALLER
    function: OP_RETURN
name: BEGIN
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub END {
    1
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:Builtin
    arguments:
      - !parsetree:Constant
        context: CXT_CALLER
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_CALLER
    function: OP_RETURN
name: END
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
END {
    1
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:Builtin
    arguments:
      - !parsetree:Constant
        context: CXT_CALLER
        flags: CONST_NUMBER|NUM_INTEGER
        value: 1
    context: CXT_CALLER
    function: OP_RETURN
name: END
EOE
