#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 2;

generate_tree_and_diff( <<'EOP', <<'EOI' );
@r = ( ( map 1, @y ), ( map 2, @z ) )
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  temporary_set index=0, slot=2 (make_list context=8)
  temporary_set index=1, slot=9 (iterator (make_list context=8 (global context=8, name="y", slot=2)))
  temporary_set index=2, slot=5 (global context=4, name="_", slot=5)
  localize_glob_slot index=3, name="_", slot=1
  jump to=L2
L10: # scope=1
  jump to=L11
L11: # scope=1
  set index=4, slot=VALUE_ARRAY (temporary index=4, slot=2)
  temporary_clear index=4, slot=2
  assign_list common=1, context=2 (make_list context=8 (get index=2, slot=VALUE_ARRAY), (get index=4, slot=VALUE_ARRAY)), (global context=24, name="r", slot=2)
  jump to=L12
L12: # scope=1
  end
L2: # scope=1
  set index=1, slot=VALUE_SCALAR (iterator_next (temporary index=1, slot=9))
  jump_if_null to=L5 (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L3: # scope=1
  swap_glob_slot_set slot=1 (get index=1, slot=VALUE_SCALAR), (temporary index=2, slot=5)
  push_element (temporary index=0, slot=2), (constant_integer value=1)
  jump to=L2
L5: # scope=1
  jump to=L6
L6: # scope=1
  set index=2, slot=VALUE_ARRAY (temporary index=0, slot=2)
  temporary_clear index=0, slot=2
  temporary_set index=4, slot=2 (make_list context=8)
  temporary_set index=5, slot=9 (iterator (make_list context=8 (global context=8, name="z", slot=2)))
  temporary_set index=6, slot=5 (global context=4, name="_", slot=5)
  localize_glob_slot index=7, name="_", slot=1
  jump to=L7
L7: # scope=1
  set index=3, slot=VALUE_SCALAR (iterator_next (temporary index=5, slot=9))
  jump_if_null to=L10 (get index=3, slot=VALUE_SCALAR)
  jump to=L8
L8: # scope=1
  swap_glob_slot_set slot=1 (get index=3, slot=VALUE_SCALAR), (temporary index=6, slot=5)
  push_element (temporary index=4, slot=2), (constant_integer value=2)
  jump to=L7
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
@x = map { $_ / 2 } @x
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  temporary_set index=0, slot=2 (make_list context=8)
  temporary_set index=1, slot=9 (iterator (make_list context=8 (global context=8, name="x", slot=2)))
  temporary_set index=2, slot=5 (global context=4, name="_", slot=5)
  localize_glob_slot index=3, name="_", slot=1
  jump to=L2
L2: # scope=1
  set index=1, slot=1 (iterator_next (temporary index=1, slot=9))
  jump_if_null to=L5 (get index=1, slot=1)
  jump to=L3
L3: # scope=1
  swap_glob_slot_set slot=1 (get index=1, slot=1), (temporary index=2, slot=5)
  set index=2, slot=2 (temporary index=0, slot=2)
  jump to=L7
L5: # scope=1
  jump to=L6
L6: # scope=1
  set index=3, slot=2 (temporary index=0, slot=2)
  temporary_clear index=0, slot=2
  assign_list common=1, context=2 (get index=3, slot=2), (global context=24, name="x", slot=2)
  jump to=L8
L7: # scope=2
  push_element (get index=2, slot=2), (divide context=8 (global context=4, name="_", slot=1), (constant_integer value=2))
  jump to=L2
L8: # scope=1
  end
EOI
