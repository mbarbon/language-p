#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 2;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = do {
    1;
    2;
}
EOP
# main
L1:
  lexical_state_set index=0
  jump to=L2
L2:
  constant_integer value=1
  assign context=2 (global context=20, name="x", slot=1), (constant_integer value=2)
  jump to=L3
L3:
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = do {
    local $x = 1;
    1;
    2;
}
EOP
# main
L1:
  lexical_state_set index=0
  jump to=L2
L2:
  assign context=2 (localize_glob_slot index=0, name="x", slot=1), (constant_integer value=1)
  constant_integer value=1
  set index=1, slot=VALUE_SCALAR (constant_integer value=2)
  restore_glob_slot index=0, name="x", slot=1
  assign context=2 (global context=20, name="x", slot=1), (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L3:
  end
EOI
