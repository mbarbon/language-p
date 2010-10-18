#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
@r = map 1, @y
EOP
# main
L1:
  temporary_set index=0, slot=2 (make_list context=8)
  temporary_set index=1, slot=9 (iterator (make_list context=8 (make_list context=8 (global context=8, name="y", slot=2))))
  temporary_set index=2, slot=5 (global context=4, name="_", slot=5)
  localize_glob_slot index=3, name="_", slot=1
  jump to=L2
L2:
  set index=1 (iterator_next (temporary index=1, slot=9))
  jump_if_null to=L5 (get index=1)
  jump to=L3
L3:
  glob_slot_set slot=1 (temporary index=2, slot=5), (get index=1)
  push_element (temporary index=0, slot=2), (constant_integer value=1)
  jump to=L2
L5:
  jump to=L6
L6:
  set index=2 (temporary index=0, slot=2)
  temporary_clear index=0, slot=2
  assign context=2 (global context=24, name="r", slot=2), (get index=2)
  jump to=L7
L7:
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
@r = grep 1, @y
EOP
# main
L1:
  temporary_set index=0, slot=2 (make_list context=8)
  temporary_set index=1, slot=9 (iterator (make_list context=8 (make_list context=8 (global context=8, name="y", slot=2))))
  temporary_set index=2, slot=5 (global context=4, name="_", slot=5)
  localize_glob_slot index=3, name="_", slot=1
  jump to=L2
L10:
  jump to=L2
L2:
  set index=1 (iterator_next (temporary index=1, slot=9))
  jump_if_null to=L5 (get index=1)
  jump to=L3
L3:
  glob_slot_set slot=1 (temporary index=2, slot=5), (get index=1)
  jump_if_true to=L7 (constant_integer value=1)
  jump to=L10
L5:
  jump to=L6
L6:
  set index=2 (temporary index=0, slot=2)
  temporary_clear index=0, slot=2
  assign context=2 (global context=24, name="r", slot=2), (get index=2)
  jump to=L9
L7:
  push_element (temporary index=0, slot=2), (global context=4, name="_", slot=1)
  jump to=L2
L9:
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
@r = ( ( map 1, @y ), ( map 2, @z ) )
EOP
# main
L1:
  temporary_set index=0, slot=2 (make_list context=8)
  temporary_set index=1, slot=9 (iterator (make_list context=8 (make_list context=8 (global context=8, name="y", slot=2))))
  temporary_set index=2, slot=5 (global context=4, name="_", slot=5)
  localize_glob_slot index=3, name="_", slot=1
  jump to=L2
L10:
  jump to=L11
L11:
  set index=5 (temporary index=4, slot=2)
  temporary_clear index=4, slot=2
  assign context=2 (global context=24, name="r", slot=2), (make_list context=8 (get index=4), (get index=5))
  jump to=L12
L12:
  end
L2:
  set index=1 (iterator_next (temporary index=1, slot=9))
  jump_if_null to=L5 (get index=1)
  jump to=L3
L3:
  glob_slot_set slot=1 (temporary index=2, slot=5), (get index=1)
  push_element (temporary index=0, slot=2), (constant_integer value=1)
  jump to=L2
L5:
  jump to=L6
L6:
  set index=2 (temporary index=0, slot=2)
  temporary_clear index=0, slot=2
  temporary_set index=4, slot=2 (make_list context=8)
  temporary_set index=5, slot=9 (iterator (make_list context=8 (make_list context=8 (global context=8, name="z", slot=2))))
  temporary_set index=6, slot=5 (global context=4, name="_", slot=5)
  localize_glob_slot index=7, name="_", slot=1
  jump to=L7
L7:
  set index=3 (iterator_next (temporary index=5, slot=9))
  set index=4 (phi L6, 2, L8, 4)
  jump_if_null to=L10 (get index=3)
  jump to=L8
L8:
  glob_slot_set slot=1 (temporary index=6, slot=5), (get index=3)
  push_element (temporary index=4, slot=2), (constant_integer value=2)
  jump to=L7
EOI
