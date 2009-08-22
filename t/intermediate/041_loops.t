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
  scope_enter scope=0
  scope_enter scope=1
  constant_integer value=0
  global name="i", slot=1
  swap
  assign
  pop
  jump to=L2
L2:
  global name="i", slot=1
  constant_integer value=10
  jump_if_f_lt false=L5, true=L3
L3:
  scope_enter scope=2
  global name="STDOUT", slot=7
  global name="i", slot=1
  make_list count=1
  print context=2
  pop
  scope_leave scope=2
  jump to=L4
L4:
  global name="i", slot=1
  constant_integer value=1
  add context=4
  global name="i", slot=1
  swap
  assign
  pop
  jump to=L2
L5:
  scope_leave scope=1
  scope_leave scope=0
  end
EOI
