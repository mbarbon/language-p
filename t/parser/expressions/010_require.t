#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
require 'Foo.pm';
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: Foo.pm
context: CXT_VOID
function: OP_REQUIRE_FILE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
require Foo::Bar'Baz;
EOP
--- !parsetree:Builtin
arguments:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: Foo/Bar/Baz.pm
context: CXT_VOID
function: OP_REQUIRE_FILE
EOE
