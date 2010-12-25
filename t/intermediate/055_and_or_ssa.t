#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 8;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1, slot=VALUE_SCALAR)
  jump to=L6
L2:
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3, slot=VALUE_SCALAR (phi L2, 2, VALUE_SCALAR, L6, 1, VALUE_SCALAR)
  assign context=2 (global context=20, name="x", slot=1), (get index=3, slot=VALUE_SCALAR)
  jump to=L5
L5:
  end
L6:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$a &&= $b;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=20, name="a", slot=1)
  jump_if_true to=L2 (get index=1, slot=VALUE_SCALAR)
  jump to=L4
L2:
  assign context=2 (get index=1, slot=VALUE_SCALAR), (global context=4, name="b", slot=1)
  jump to=L3
L3:
  end
L4:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L6 (get index=1, slot=VALUE_SCALAR)
  jump to=L2
L2:
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3, slot=VALUE_SCALAR (phi L6, 1, VALUE_SCALAR, L2, 2, VALUE_SCALAR)
  assign context=2 (global context=20, name="x", slot=1), (get index=3, slot=VALUE_SCALAR)
  jump to=L5
L5:
  end
L6:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$a ||= $b;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=20, name="a", slot=1)
  jump_if_true to=L4 (get index=1, slot=VALUE_SCALAR)
  jump to=L2
L2:
  assign context=2 (get index=1, slot=VALUE_SCALAR), (global context=4, name="b", slot=1)
  jump to=L3
L3:
  end
L4:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1, slot=VALUE_SCALAR)
  jump to=L9
L10:
  jump to=L6
L2:
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3, slot=VALUE_SCALAR (phi L2, 2, VALUE_SCALAR, L9, 1, VALUE_SCALAR)
  jump_if_true to=L5 (get index=3, slot=VALUE_SCALAR)
  jump to=L10
L5:
  set index=4, slot=VALUE_SCALAR (global context=4, name="c", slot=1)
  jump to=L6
L6:
  set index=5, slot=VALUE_SCALAR (phi L5, 4, VALUE_SCALAR, L10, 3, VALUE_SCALAR)
  assign context=2 (global context=20, name="x", slot=1), (get index=5, slot=VALUE_SCALAR)
  jump to=L8
L8:
  end
L9:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$a && $b && $c;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1, slot=VALUE_SCALAR)
  jump to=L8
L2:
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3, slot=VALUE_SCALAR (phi L2, 2, VALUE_SCALAR, L8, 1, VALUE_SCALAR)
  jump_if_true to=L5 (get index=3, slot=VALUE_SCALAR)
  jump to=L7
L5:
  global context=2, name="c", slot=1
  jump to=L6
L6:
  end
L7:
  jump to=L6
L8:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L9 (get index=1, slot=VALUE_SCALAR)
  jump to=L2
L10:
  jump to=L6
L2:
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3, slot=VALUE_SCALAR (phi L9, 1, VALUE_SCALAR, L2, 2, VALUE_SCALAR)
  jump_if_true to=L10 (get index=3, slot=VALUE_SCALAR)
  jump to=L5
L5:
  set index=4, slot=VALUE_SCALAR (global context=4, name="c", slot=1)
  jump to=L6
L6:
  set index=5, slot=VALUE_SCALAR (phi L10, 3, VALUE_SCALAR, L5, 4, VALUE_SCALAR)
  assign context=2 (global context=20, name="x", slot=1), (get index=5, slot=VALUE_SCALAR)
  jump to=L8
L8:
  end
L9:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $a || $b;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=VALUE_SCALAR)
  set index=2, slot=VALUE_HANDLE (global context=4, name="STDOUT", slot=VALUE_HANDLE)
  jump_if_true to=L6 (get index=1, slot=VALUE_SCALAR)
  jump to=L2
L2:
  set index=3, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=4, slot=VALUE_SCALAR (phi L6, VALUE_SCALAR, 1, L2, 3, VALUE_SCALAR)
  set index=5, slot=VALUE_HANDLE (get index=2, slot=VALUE_HANDLE)
  print context=2 (get index=5, slot=VALUE_HANDLE), (make_array context=8 (get index=4, slot=VALUE_SCALAR))
  jump to=L5
L5:
  end
L6:
  jump to=L3
EOI
