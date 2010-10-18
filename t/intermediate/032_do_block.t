#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 2;

generate_and_diff( <<'EOP', <<'EOI' );
$x = do {
    1;
    2;
}
EOP
# main
L1:
  constant_integer value=1
  pop
  constant_integer value=2
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = do {
    local $x = 1;
    1;
    2;
}
EOP
# main
L1:
  constant_integer value=1
  localize_glob_slot index=0, name="x", slot=1
  swap
  assign context=2
  pop
  constant_integer value=1
  pop
  constant_integer value=2
  restore_glob_slot index=0, name="x", slot=1
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L2:
  end
EOI
