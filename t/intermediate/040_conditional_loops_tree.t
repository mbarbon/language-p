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
  jump to=L2
L2:
  jump_if_true to=L3 (global name="a", slot=1)
  jump to=L5
L3:
  assign context=2 (global name="x", slot=1), (add context=4 (constant_integer value=1), (constant_integer value=1))
  jump to=L2
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
  jump to=L2
L2:
  jump_if_true to=L3 (global name="a", slot=1)
  jump to=L5
L3:
  assign context=2 (global name="x", slot=1), (constant_integer value=1)
  jump to=L4
L4:
  assign context=2 (global name="y", slot=1), (constant_integer value=2)
  jump to=L2
L5:
  end
EOI
