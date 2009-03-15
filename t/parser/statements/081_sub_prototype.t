#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x();
EOP
--- !parsetree:SubroutineDeclaration
name: x
prototype:
  - 0
  - 0
  - 0
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x($);
EOP
--- !parsetree:SubroutineDeclaration
name: x
prototype:
  - 1
  - 1
  - 0
  - PROTO_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x(;$);
EOP
--- !parsetree:SubroutineDeclaration
name: x
prototype:
  - 0
  - 1
  - 0
  - PROTO_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x(&@);
EOP
--- !parsetree:SubroutineDeclaration
name: x
prototype:
  - 1
  - -1
  - PROTO_SUB
  - PROTO_SUB
  - PROTO_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x(%);
EOP
--- !parsetree:SubroutineDeclaration
name: x
prototype:
  - 0
  - -1
  - 0
  - PROTO_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x(;$@);
EOP
--- !parsetree:SubroutineDeclaration
name: x
prototype:
  - 0
  - -1
  - 0
  - PROTO_SCALAR
  - PROTO_ARRAY
EOE
