#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
for( $i = 0; $i < 10; $i = $i + 1 ) {
  print $i;
}
EOP
# main
L1:
  constant_integer value=0
  global name="i", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L2:
  global name="i", slot=1
  constant_integer value=10
  jump_if_f_lt false=L5, true=L3
L3:
  global name="STDOUT", slot=7
  global name="i", slot=1
  make_array count=1, context=8
  print context=2
  pop
  jump to=L4
L4:
  global name="i", slot=1
  constant_integer value=1
  add context=4
  global name="i", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L5:
  end
EOI
