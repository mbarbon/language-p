#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b : $c + 3;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump_if_f_gt to=L3 (global context=4, name="a", slot=1), (constant_integer value=2)
  jump to=L4
L2: # scope=1
  assign context=2 (get index=3, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L5
L3: # scope=1
  set index=1, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L2
L4: # scope=1
  set index=2, slot=VALUE_SCALAR (add context=4 (global context=4, name="c", slot=1), (constant_integer value=3))
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L2
L5: # scope=0
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b :
     $c < 3 ? $d : $e;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump_if_f_gt to=L3 (global context=4, name="a", slot=1), (constant_integer value=2)
  jump to=L4
L2: # scope=1
  assign context=2 (get index=5, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L8
L3: # scope=1
  set index=1, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  set index=5, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L2
L4: # scope=1
  jump_if_f_lt to=L6 (global context=4, name="c", slot=1), (constant_integer value=3)
  jump to=L7
L5: # scope=1
  set index=5, slot=1 (get index=4, slot=1)
  jump to=L2
L6: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="d", slot=1)
  set index=4, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L5
L7: # scope=1
  set index=3, slot=VALUE_SCALAR (global context=4, name="e", slot=1)
  set index=4, slot=VALUE_SCALAR (get index=3, slot=VALUE_SCALAR)
  jump to=L5
L8: # scope=0
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? %x : \%x;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump_if_f_gt to=L3 (global context=4, name="a", slot=1), (constant_integer value=2)
  jump to=L4
L2: # scope=1
  assign context=2 (get index=3, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L5
L3: # scope=1
  set index=1, slot=VALUE_HASH (global context=4, name="x", slot=3)
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_HASH)
  jump to=L2
L4: # scope=1
  set index=2, slot=VALUE_SCALAR (reference context=4 (global context=4, name="x", slot=3))
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L2
L5: # scope=0
  end
EOI
