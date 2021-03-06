#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_linear_and_diff( <<'EOP', <<'EOI' );
foreach $y ( 1, 2 ) {
  3
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  constant_integer value=1
  constant_integer value=2
  make_list arg_count=2, context=8
  iterator
  temporary_set index=0, slot=9
  global context=4, name="y", slot=5
  temporary_set index=1, slot=5
  localize_glob_slot index=2, name="y", slot=1
  pop
  jump to=L3
L3: # scope=2
  temporary index=0, slot=9
  iterator_next
  dup
  jump_if_null false=L4, true=L6
L4: # scope=2
  temporary index=1, slot=5
  swap_glob_slot_set slot=1
  jump to=L8
L6: # scope=2
  pop
  jump to=L7
L7: # scope=1
  temporary_clear index=1, slot=5
  restore_glob_slot index=2, name="y", slot=1
  jump to=L9
L8: # scope=3
  constant_integer value=3
  pop
  jump to=L3
L9: # scope=1
  end
EOI

