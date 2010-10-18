#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1:
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L6
L2:
  set index=2 (global context=4, name="b", slot=1)
  set index=3 (get index=2)
  jump to=L3
L3:
  assign context=2 (global context=20, name="x", slot=1), (get index=3)
  jump to=L5
L5:
  end
L6:
  set index=3 (get index=1)
  jump to=L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L6 (get index=1)
  jump to=L2
L2:
  set index=2 (global context=4, name="b", slot=1)
  set index=3 (get index=2)
  jump to=L3
L3:
  assign context=2 (global context=20, name="x", slot=1), (get index=3)
  jump to=L5
L5:
  end
L6:
  set index=3 (get index=1)
  jump to=L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L9
L10:
  set index=5 (get index=3)
  jump to=L6
L2:
  set index=2 (global context=4, name="b", slot=1)
  set index=3 (get index=2)
  jump to=L3
L3:
  jump_if_true to=L5 (get index=3)
  jump to=L10
L5:
  set index=4 (global context=4, name="c", slot=1)
  set index=5 (get index=4)
  jump to=L6
L6:
  assign context=2 (global context=20, name="x", slot=1), (get index=5)
  jump to=L8
L8:
  end
L9:
  set index=3 (get index=1)
  jump to=L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  set index=1 (global context=4, name="a", slot=1)
  jump_if_true to=L9 (get index=1)
  jump to=L2
L10:
  set index=5 (get index=3)
  jump to=L6
L2:
  set index=2 (global context=4, name="b", slot=1)
  set index=3 (get index=2)
  jump to=L3
L3:
  jump_if_true to=L10 (get index=3)
  jump to=L5
L5:
  set index=4 (global context=4, name="c", slot=1)
  set index=5 (get index=4)
  jump to=L6
L6:
  assign context=2 (global context=20, name="x", slot=1), (get index=5)
  jump to=L8
L8:
  end
L9:
  set index=3 (get index=1)
  jump to=L3
EOI
