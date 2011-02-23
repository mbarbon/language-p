#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1, slot=VALUE_SCALAR)
  jump to=L4
L2: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L3
L3: # scope=1
  assign context=2 (get index=3, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L5
L4: # scope=1
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L5: # scope=0
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L4 (get index=1, slot=VALUE_SCALAR)
  jump to=L2
L2: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L3
L3: # scope=1
  assign context=2 (get index=3, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L5
L4: # scope=1
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L5: # scope=0
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1, slot=VALUE_SCALAR)
  jump to=L4
L2: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L3
L3: # scope=1
  jump_if_true to=L5 (get index=3, slot=VALUE_SCALAR)
  jump to=L7
L4: # scope=1
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L5: # scope=1
  set index=4, slot=VALUE_SCALAR (global context=4, name="c", slot=1)
  set index=5, slot=VALUE_SCALAR (get index=4, slot=VALUE_SCALAR)
  jump to=L6
L6: # scope=1
  assign context=2 (get index=5, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L8
L7: # scope=1
  set index=5, slot=VALUE_SCALAR (get index=3, slot=VALUE_SCALAR)
  jump to=L6
L8: # scope=0
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L4 (get index=1, slot=VALUE_SCALAR)
  jump to=L2
L2: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L3
L3: # scope=1
  jump_if_true to=L7 (get index=3, slot=VALUE_SCALAR)
  jump to=L5
L4: # scope=1
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L3
L5: # scope=1
  set index=4, slot=VALUE_SCALAR (global context=4, name="c", slot=1)
  set index=5, slot=VALUE_SCALAR (get index=4, slot=VALUE_SCALAR)
  jump to=L6
L6: # scope=1
  assign context=2 (get index=5, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L8
L7: # scope=1
  set index=5, slot=VALUE_SCALAR (get index=3, slot=VALUE_SCALAR)
  jump to=L6
L8: # scope=0
  end
EOI
