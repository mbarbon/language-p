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
# main
L1:
  scope_enter scope=0
  jump to=L2
L2:
  scope_enter scope=1
  global name="a", slot=1
  jump_if_true false=L5, true=L3
L3:
  scope_enter scope=2
  constant_integer value=1
  pop
  scope_leave scope=2
  jump to=L2
L5:
  scope_leave scope=1
  scope_leave scope=0
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
until( $a ) {
    1;
}
EOP
# main
L1:
  scope_enter scope=0
  jump to=L2
L2:
  scope_enter scope=1
  global name="a", slot=1
  jump_if_true false=L3, true=L5
L3:
  scope_enter scope=2
  constant_integer value=1
  pop
  scope_leave scope=2
  jump to=L2
L5:
  scope_leave scope=1
  scope_leave scope=0
  end
EOI
