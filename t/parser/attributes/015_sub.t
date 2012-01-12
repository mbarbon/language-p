#!/usr/bin/perl -w

use t::lib::TestParser tests => 3;

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo : Bar;
EOP
--- !parsetree:SubroutineDeclaration
attributes:
  - Bar
name: foo
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo : Bar { }
EOP
--- !parsetree:NamedSubroutine
attributes:
  - Bar
lines: []
name: foo
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub foo($) : Bar { }
EOP
--- !parsetree:NamedSubroutine
attributes:
  - Bar
lines: []
name: foo
prototype:
  - 1
  - 1
  - 0
  - 1
EOE
