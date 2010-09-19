#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_and_diff( <<'EOP', <<'EOI' );
@r = map 1, @y
EOP
# main
L1:
  make_list context=8, count=0
  temporary_set index=0, slot=2
  global context=8, name="y", slot=2
  make_list context=8, count=1
  make_list context=8, count=1
  iterator
  temporary_set index=1, slot=9
  global context=4, name="_", slot=5
  temporary_set index=2, slot=5
  localize_glob_slot index=3, name="_", slot=1
  pop
  jump to=L2
L2:
  temporary index=1, slot=9
  iterator_next
  dup
  jump_if_null false=L3, true=L5
L3:
  temporary index=2, slot=5
  swap
  glob_slot_set slot=1
  temporary index=0, slot=2
  constant_integer value=1
  push_element
  jump to=L2
L5:
  pop
  jump to=L6
L6:
  temporary index=0, slot=2
  temporary_clear index=0, slot=2
  global context=24, name="r", slot=2
  swap
  assign context=2
  pop
  jump to=L7
L7:
  end
EOI
