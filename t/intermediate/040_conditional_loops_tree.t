#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_tree_and_diff( <<'EOP', <<'EOI' );
while( $a ) {
  $x = 1 + 1;
}
EOP
# main
L1:
  jump L2
L2:
  jump_if_true (global name=a, slot=1), L3
  jump L5
L3:
  assign (global name=x, slot=1), (add (constant_integer 1), (constant_integer 1))
  jump L2
L5:
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
while( $a ) {
  $x = 1;
} continue {
  $y = 2;
}
EOP
# main
L1:
  jump L2
L2:
  jump_if_true (global name=a, slot=1), L3
  jump L5
L3:
  assign (global name=x, slot=1), (constant_integer 1)
  jump L4
L4:
  assign (global name=y, slot=1), (constant_integer 2)
  jump L2
L5:
  end
EOI
