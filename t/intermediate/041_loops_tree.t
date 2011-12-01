#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_tree_and_diff( <<'EOP', <<'EOI' );
for( $i = 0; $i < 10; $i = $i + 1 ) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L6
L2: # scope=1
  jump_if_f_lt to=L3 (global context=4, name="i", slot=1), (constant_integer value=10)
  jump to=L5
L3: # scope=3
  print context=2 (global context=4, name="STDOUT", slot=7), (make_array context=8 (global context=4, name="i", slot=1))
  jump to=L4
L4: # scope=1
  assign context=2 (add context=4 (global context=4, name="i", slot=1), (constant_integer value=1)), (global context=20, name="i", slot=1)
  jump to=L2
L5: # scope=1
  end
L6: # scope=2
  assign context=2 (constant_integer value=0), (global context=20, name="i", slot=1)
  jump to=L2
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
LABEL: for( $i = 0; $i < 0; $i = $i + 1 ) {
    redo LABEL
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  assign context=2 (constant_integer value=0), (global context=20, name="i", slot=1)
  jump to=L3
L3: # scope=1
  jump_if_f_lt to=L7 (global context=4, name="i", slot=1), (constant_integer value=0)
  jump to=L6
L4: # scope=3
  jump to=L4
L6: # scope=1
  end
L7: # scope=1
  jump to=L4
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
foreach $i ( 1, 2 ) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L7
L2: # scope=1
  set index=1, slot=VALUE_SCALAR (iterator_next (temporary index=0, slot=VALUE_ITERATOR))
  jump_if_null to=L5 (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L3: # scope=1
  swap_glob_slot_set slot=1 (get index=1, slot=VALUE_SCALAR), (temporary index=1, slot=5)
  jump to=L8
L5: # scope=1
  jump to=L6
L6: # scope=1
  temporary_clear index=1, slot=5
  restore_glob_slot index=2, name="i", slot=1
  jump to=L9
L7: # scope=2
  temporary_set index=0, slot=9 (iterator (make_list context=8 (constant_integer value=1), (constant_integer value=2)))
  temporary_set index=1, slot=5 (global context=4, name="i", slot=5)
  localize_glob_slot index=2, name="i", slot=1
  jump to=L2
L8: # scope=3
  print context=2 (global context=4, name="STDOUT", slot=7), (make_array context=8 (global context=4, name="i", slot=1))
  jump to=L2
L9: # scope=1
  end
EOI
