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
# main
L1:
  constant_integer value=1
  constant_integer value=2
  make_list context=8, count=2
  make_list context=8, count=1
  iterator
  temporary_set index=0, slot=9
  global context=4, name="y", slot=5
  temporary_set index=1, slot=5
  localize_glob_slot index=2, name="y", slot=1
  pop
  jump to=L2
L2:
  temporary index=0, slot=9
  iterator_next
  dup
  jump_if_null false=L3, true=L5
L3:
  temporary index=1, slot=5
  swap
  glob_slot_set slot=1
  jump to=L7
L5:
  pop
  jump to=L6
L6:
  temporary_clear index=1, slot=5
  restore_glob_slot index=2, name="y", slot=1
  jump to=L8
L7:
  constant_integer value=3
  pop
  jump to=L2
L8:
  end
EOI

