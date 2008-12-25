#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
while( $a ) {
    1;
}
EOP
L1:
  jump to=L2
L2:
  global name=a, slot=1
  jump_if_true false=L5, true=L3
L3:
  constant_integer 1
  pop
  jump to=L2
L5:
EOI

generate_and_diff( <<'EOP', <<'EOI' );
until( $a ) {
    1;
}
EOP
L1:
  jump to=L2
L2:
  global name=a, slot=1
  jump_if_true false=L3, true=L5
L3:
  constant_integer 1
  pop
  jump to=L2
L5:
EOI
