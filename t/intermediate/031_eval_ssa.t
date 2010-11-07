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
  undef (global context=4, name="@", slot=1)
  constant_integer value=1
  set index=1 (constant_integer value=2)
  undef (global context=4, name="@", slot=1)
  jump to=L3
L2:
  set index=2 (constant_undef)
  jump to=L3
L3:
  set index=3 (phi L1, 1, L2, 2)
  assign context=2 (global context=20, name="x", slot=1), (get index=3)
  jump to=L4
L4:
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
  undef (global context=4, name="@", slot=1)
  constant_integer value=1
  constant_integer value=2
  undef (global context=4, name="@", slot=1)
  jump to=L3
L2:
  jump to=L3
L3:
  end
EOI