#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 8;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true false=L4, true=L2 (get index=1, slot=VALUE_SCALAR)
L2: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3: # scope=1
  set index=3, slot=VALUE_SCALAR (phi blocks=[L4, L2], indices=[1, 2], slots=[VALUE_SCALAR, VALUE_SCALAR])
  assign context=2 (get index=3, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L5
L4: # scope=1
  jump to=L3
L5: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$a &&= $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=20, name="a", slot=1)
  jump_if_true false=L4, true=L2 (get index=1, slot=VALUE_SCALAR)
L2: # scope=1
  swap_assign context=2 (get index=1, slot=VALUE_SCALAR), (global context=4, name="b", slot=1)
  jump to=L3
L3: # scope=1
  end
L4: # scope=1
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true false=L2, true=L4 (get index=1, slot=VALUE_SCALAR)
L2: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3: # scope=1
  set index=3, slot=VALUE_SCALAR (phi blocks=[L4, L2], indices=[1, 2], slots=[VALUE_SCALAR, VALUE_SCALAR])
  assign context=2 (get index=3, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L5
L4: # scope=1
  jump to=L3
L5: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$a ||= $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=20, name="a", slot=1)
  jump_if_true false=L2, true=L4 (get index=1, slot=VALUE_SCALAR)
L2: # scope=1
  swap_assign context=2 (get index=1, slot=VALUE_SCALAR), (global context=4, name="b", slot=1)
  jump to=L3
L3: # scope=1
  end
L4: # scope=1
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true false=L4, true=L2 (get index=1, slot=VALUE_SCALAR)
L2: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3: # scope=1
  set index=3, slot=VALUE_SCALAR (phi blocks=[L4, L2], indices=[1, 2], slots=[VALUE_SCALAR, VALUE_SCALAR])
  jump_if_true false=L7, true=L5 (get index=3, slot=VALUE_SCALAR)
L4: # scope=1
  jump to=L3
L5: # scope=1
  set index=4, slot=VALUE_SCALAR (global context=4, name="c", slot=1)
  jump to=L6
L6: # scope=1
  set index=5, slot=VALUE_SCALAR (phi blocks=[L7, L5], indices=[3, 4], slots=[VALUE_SCALAR, VALUE_SCALAR])
  assign context=2 (get index=5, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L8
L7: # scope=1
  jump to=L6
L8: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$a && $b && $c;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true false=L4, true=L2 (get index=1, slot=VALUE_SCALAR)
L2: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3: # scope=1
  set index=3, slot=VALUE_SCALAR (phi blocks=[L4, L2], indices=[1, 2], slots=[VALUE_SCALAR, VALUE_SCALAR])
  jump_if_true false=L7, true=L5 (get index=3, slot=VALUE_SCALAR)
L4: # scope=1
  jump to=L3
L5: # scope=1
  global context=2, name="c", slot=1
  jump to=L6
L6: # scope=1
  end
L7: # scope=1
  jump to=L6
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true false=L2, true=L4 (get index=1, slot=VALUE_SCALAR)
L2: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3: # scope=1
  set index=3, slot=VALUE_SCALAR (phi blocks=[L4, L2], indices=[1, 2], slots=[VALUE_SCALAR, VALUE_SCALAR])
  jump_if_true false=L5, true=L7 (get index=3, slot=VALUE_SCALAR)
L4: # scope=1
  jump to=L3
L5: # scope=1
  set index=4, slot=VALUE_SCALAR (global context=4, name="c", slot=1)
  jump to=L6
L6: # scope=1
  set index=5, slot=VALUE_SCALAR (phi blocks=[L7, L5], indices=[3, 4], slots=[VALUE_SCALAR, VALUE_SCALAR])
  assign context=2 (get index=5, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L8
L7: # scope=1
  jump to=L6
L8: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $a || $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_HANDLE (global context=4, name="STDOUT", slot=VALUE_HANDLE)
  set index=2, slot=VALUE_SCALAR (global context=4, name="a", slot=VALUE_SCALAR)
  jump_if_true false=L2, true=L4 (get index=2, slot=VALUE_SCALAR)
L2: # scope=1
  set index=3, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3: # scope=1
  set index=4, slot=VALUE_SCALAR (phi blocks=[L4, L2], indices=[2, 3], slots=[VALUE_SCALAR, VALUE_SCALAR])
  print context=2 (get index=1, slot=VALUE_HANDLE), (make_array context=8 (get index=4, slot=VALUE_SCALAR))
  jump to=L5
L4: # scope=1
  jump to=L3
L5: # scope=1
  end
EOI
