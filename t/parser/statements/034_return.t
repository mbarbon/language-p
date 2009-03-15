#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    return @y;
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:Builtin
    arguments:
      - !parsetree:Symbol
        context: CXT_CALLER
        name: y
        sigil: VALUE_ARRAY
    context: CXT_CALLER
    function: OP_RETURN
name: x
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    @x;
    @y;
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:Symbol
    context: CXT_VOID
    name: x
    sigil: VALUE_ARRAY
  - !parsetree:Builtin
    arguments:
      - !parsetree:Symbol
        context: CXT_CALLER
        name: y
        sigil: VALUE_ARRAY
    context: CXT_CALLER
    function: OP_RETURN
name: x
prototype: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    if( $a ) {
        @y;
    }
}
EOP
--- !parsetree:NamedSubroutine
lines:
  - !parsetree:Conditional
    iffalse: ~
    iftrues:
      - !parsetree:ConditionalBlock
        block: !parsetree:Block
          lines:
            - !parsetree:Builtin
              arguments:
                - !parsetree:Symbol
                  context: CXT_CALLER
                  name: y
                  sigil: VALUE_ARRAY
              context: CXT_CALLER
              function: OP_RETURN
        block_type: if
        condition: !parsetree:Symbol
          context: CXT_SCALAR
          name: a
          sigil: VALUE_SCALAR
name: x
prototype: ~
EOE
