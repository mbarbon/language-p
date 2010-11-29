#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
foreach $y ( 1, 2 ) {
  3
}
EOP
# main
L1:
  temporary_set index=0, slot=9 (iterator (make_list context=8 (make_list context=8 (constant_integer value=1), (constant_integer value=2))))
  temporary_set index=1, slot=5 (global context=4, name="y", slot=5)
  localize_glob_slot index=2, name="y", slot=1
  jump to=L2
L2:
  set index=1, slot=VALUE_SCALAR (iterator_next (temporary index=0, slot=9))
  jump_if_null to=L5 (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L3:
  glob_slot_set slot=1 (temporary index=1, slot=5), (get index=1, slot=VALUE_SCALAR)
  jump to=L7
L5:
  jump to=L6
L6:
  temporary_clear index=1, slot=5
  restore_glob_slot index=2, name="y", slot=1
  jump to=L8
L7:
  constant_integer value=3
  jump to=L2
L8:
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
foreach my $y ( 1, 2 ) {
  3
}
EOP
# main
L1:
  temporary_set index=0, slot=9 (iterator (make_list context=8 (make_list context=8 (constant_integer value=1), (constant_integer value=2))))
  jump to=L2
L2:
  set index=1, slot=VALUE_SCALAR (iterator_next (temporary index=0, slot=9))
  jump_if_null to=L5 (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L3:
  lexical_set index=0 (get index=1, slot=VALUE_SCALAR)
  jump to=L7
L5:
  jump to=L6
L6:
  end
L7:
  constant_integer value=3
  jump to=L2
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
my $y;
foreach $y ( 1, 2 ) {
  3
}
EOP
# main
L1:
  lexical_pad index=0, slot=1
  jump to=L7
L2:
  set index=1, slot=VALUE_SCALAR (iterator_next (temporary index=0, slot=9))
  jump_if_null to=L5 (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L3:
  lexical_pad_set index=0 (get index=1, slot=VALUE_SCALAR)
  jump to=L8
L5:
  jump to=L6
L6:
  restore_lexical_pad index=1, lexical=0
  jump to=L9
L7:
  temporary_set index=0, slot=9 (iterator (make_list context=8 (make_list context=8 (constant_integer value=1), (constant_integer value=2))))
  localize_lexical_pad index=1, lexical=0
  jump to=L2
L8:
  constant_integer value=3
  jump to=L2
L9:
  end
EOI
