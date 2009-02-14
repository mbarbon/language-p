#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
foreach $y ( 1, 2 ) {
  3
}
EOP
L1:
  constant_integer 1
  constant_integer 2
  make_list count=2
  make_list count=1
  iterator
  temporary_set index=0
  global name=y, slot=5
  dup
  glob_slot slot=1
  temporary_set index=2
  temporary_set index=1
  jump to=L2
L2:
  temporary index=0
  iterator_next
  dup
  jump_if_null false=L3, true=L5
L3:
  temporary index=1
  swap
  glob_slot_set slot=1
  constant_integer 3
  pop
  jump to=L2
L5:
  pop
  jump to=L6
L6:
  temporary index=1
  temporary index=2
  glob_slot_set slot=1
  end
EOI

