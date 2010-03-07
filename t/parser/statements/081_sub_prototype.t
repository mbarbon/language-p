#!/usr/bin/perl -w

use t::lib::TestParser tests => 7;

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
$a = sub () { };
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: a
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:AnonymousSubroutine
  lines: []
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
