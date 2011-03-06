#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b : $c + 3;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump_if_f_gt false=L4, true=L3 (global context=4, name="a", slot=1), (constant_integer value=2)
L2: # scope=1
  set index=3, slot=VALUE_SCALAR (phi blocks=[L3, L4], indices=[1, 2], slots=[VALUE_SCALAR, VALUE_SCALAR])
  assign context=2 (get index=3, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L5
L3: # scope=1
  set index=1, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L2
L4: # scope=1
  set index=2, slot=VALUE_SCALAR (add context=4 (global context=4, name="c", slot=1), (constant_integer value=3))
  jump to=L2
L5: # scope=0
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b :
     $c < 3 ? $d : $e;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump_if_f_gt false=L4, true=L3 (global context=4, name="a", slot=1), (constant_integer value=2)
L2: # scope=1
  set index=5, slot=VALUE_SCALAR (phi blocks=[L3, L5], indices=[1, 4], slots=[VALUE_SCALAR, VALUE_SCALAR])
  assign context=2 (get index=5, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L8
L3: # scope=1
  set index=1, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L2
L4: # scope=1
  jump_if_f_lt false=L7, true=L6 (global context=4, name="c", slot=1), (constant_integer value=3)
L5: # scope=1
  set index=4, slot=1 (phi blocks=[L6, L7], indices=[2, 3], slots=[VALUE_SCALAR, VALUE_SCALAR])
  jump to=L2
L6: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="d", slot=1)
  jump to=L5
L7: # scope=1
  set index=3, slot=VALUE_SCALAR (global context=4, name="e", slot=1)
  jump to=L5
L8: # scope=0
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $a > 2 ? $b : $c;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_HANDLE (global context=4, name="STDOUT", slot=7)
  jump_if_f_gt false=L4, true=L3 (global context=4, name="a", slot=1), (constant_integer value=2)
L2: # scope=1
  set index=4, slot=VALUE_SCALAR (phi blocks=[L3, L4], indices=[2, 3], slots=[VALUE_SCALAR, VALUE_SCALAR])
  print context=2 (get index=1, slot=VALUE_HANDLE), (make_array context=8 (get index=4, slot=VALUE_SCALAR))
  jump to=L5
L3: # scope=1
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L2
L4: # scope=1
  set index=3, slot=VALUE_SCALAR (global context=4, name="c", slot=1)
  jump to=L2
L5: # scope=0
  end
EOI
