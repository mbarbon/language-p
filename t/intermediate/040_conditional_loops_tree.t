#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_tree_and_diff( <<'EOP', <<'EOI' );
while( $a ) {
  $x = 1 + 1;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  jump_if_true to=L3 (global context=4, name="a", slot=1)
  jump to=L5
L3: # scope=3
  assign context=2 (global context=20, name="x", slot=1), (add context=4 (constant_integer value=1), (constant_integer value=1))
  jump to=L2
L5: # scope=1
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
2 and last while 1
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L10: # scope=0
  jump to=L5
L2: # scope=1
  jump_if_true to=L3 (constant_integer value=1)
  jump to=L10
L3: # scope=1
  set index=1, slot=VALUE_SCALAR (constant_integer value=2)
  jump_if_true to=L6 (get index=1, slot=VALUE_SCALAR)
  jump to=L8
L5: # scope=1
  end
L6: # scope=1
  jump to=L5
L8: # scope=1
  jump to=L2
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
while( $a ) {
  $x = 1;
} continue {
  $y = 2;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  jump_if_true to=L3 (global context=4, name="a", slot=1)
  jump to=L5
L3: # scope=3
  assign context=2 (global context=20, name="x", slot=1), (constant_integer value=1)
  jump to=L4
L4: # scope=4
  assign context=2 (global context=20, name="y", slot=1), (constant_integer value=2)
  jump to=L2
L5: # scope=1
  end
EOI
