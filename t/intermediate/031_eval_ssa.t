#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 2;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = eval {
    1;
    2;
}
EOP
# main
L1:
  lexical_state_set index=0
  jump to=L2
L2:
  undef (global context=4, name="@", slot=1)
  constant_integer value=1
  set index=2, slot=VALUE_SCALAR (constant_integer value=2)
  undef (global context=4, name="@", slot=1)
  jump to=L4
L3:
  set index=1, slot=VALUE_SCALAR (constant_undef)
  jump to=L4
L4:
  set index=3, slot=VALUE_SCALAR (phi L3, 1, VALUE_SCALAR, L2, 2, VALUE_SCALAR)
  assign context=2 (global context=20, name="x", slot=1), (get index=3, slot=VALUE_SCALAR)
  jump to=L5
L5:
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
eval {
    1;
    2;
}
EOP
# main
L1:
  lexical_state_set index=0
  jump to=L2
L2:
  undef (global context=4, name="@", slot=1)
  constant_integer value=1
  constant_integer value=2
  undef (global context=4, name="@", slot=1)
  jump to=L4
L3:
  jump to=L4
L4:
  end
EOI
