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
--- !parsetree:Subroutine
lines:
  - !parsetree:Builtin
    arguments:
      - !parsetree:Symbol
        context: CXT_CALLER
        name: y
        sigil: '@'
    context: CXT_CALLER
    function: return
name: x
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    @x;
    @y;
}
EOP
--- !parsetree:Subroutine
lines:
  - !parsetree:Symbol
    context: CXT_VOID
    name: x
    sigil: '@'
  - !parsetree:Builtin
    arguments:
      - !parsetree:Symbol
        context: CXT_CALLER
        name: y
        sigil: '@'
    context: CXT_CALLER
    function: return
name: x
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
sub x {
    if( $a ) {
        @y;
    }
}
EOP
--- !parsetree:Subroutine
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
                  sigil: '@'
              context: CXT_CALLER
              function: return
        block_type: if
        condition: !parsetree:Symbol
          context: CXT_SCALAR
          name: a
          sigil: $
name: x
EOE
