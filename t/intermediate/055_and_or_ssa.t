#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 8;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1:
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L6
L2:
  set index=2 (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L2, 2, L6, 1)
  assign context=2 (global context=20, name="x", slot=1), (get index=3)
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
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L4
L2:
  assign context=2 (get index=1), (global context=4, name="b", slot=1)
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
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L6 (get index=1)
  jump to=L2
L2:
  set index=2 (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L6, 1, L2, 2)
  assign context=2 (global context=20, name="x", slot=1), (get index=3)
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
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L4 (get index=1)
  jump to=L2
L2:
  assign context=2 (get index=1), (global context=4, name="b", slot=1)
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
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L9
L10:
  jump to=L6
L2:
  set index=2 (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L2, 2, L9, 1)
  jump_if_true to=L5 (get index=3)
  jump to=L10
L5:
  set index=4 (global context=4, name="c", slot=1)
  jump to=L6
L6:
  set index=5 (phi L5, 4, L10, 3)
  assign context=2 (global context=20, name="x", slot=1), (get index=5)
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
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L8
L2:
  set index=2 (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L2, 2, L8, 1)
  jump_if_true to=L5 (get index=3)
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
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L9 (get index=1)
  jump to=L2
L10:
  jump to=L6
L2:
  set index=2 (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L9, 1, L2, 2)
  jump_if_true to=L10 (get index=3)
  jump to=L5
L5:
  set index=4 (global context=4, name="c", slot=1)
  jump to=L6
L6:
  set index=5 (phi L10, 3, L5, 4)
  assign context=2 (global context=20, name="x", slot=1), (get index=5)
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
  set index=1 (global context=4, name="a", slot=1)
  set index=2 (global context=4, name="STDOUT", slot=7)
  jump_if_true to=L6 (get index=1)
  jump to=L2
L2:
  set index=3 (global context=4, name="b", slot=1)
  jump to=L3
L3:
  set index=4 (phi L6, 1, L2, 3)
  set index=5 (get index=2)
  print context=2 (get index=5), (make_array context=8 (get index=4))
  jump to=L5
L5:
  end
L6:
  jump to=L3
EOI
