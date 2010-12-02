#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_tree_and_diff( <<'EOP', <<'EOI' );
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
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L3
L3:
  assign context=2 (global context=20, name="x", slot=1), (get index=3, slot=VALUE_SCALAR)
  jump to=L5
L5:
  end
L6:
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
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
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L3
L3:
  assign context=2 (global context=20, name="x", slot=1), (get index=3, slot=VALUE_SCALAR)
  jump to=L5
L5:
  end
L6:
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L2 (get index=1, slot=VALUE_SCALAR)
  jump to=L9
L10:
  set index=5, slot=VALUE_SCALAR (get index=3, slot=VALUE_SCALAR)
  jump to=L6
L2:
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L3
L3:
  jump_if_true to=L5 (get index=3, slot=VALUE_SCALAR)
  jump to=L10
L5:
  set index=4, slot=VALUE_SCALAR (global context=4, name="c", slot=1)
  set index=5, slot=VALUE_SCALAR (get index=4, slot=VALUE_SCALAR)
  jump to=L6
L6:
  assign context=2 (global context=20, name="x", slot=1), (get index=5, slot=VALUE_SCALAR)
  jump to=L8
L8:
  end
L9:
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="a", slot=1)
  jump_if_true to=L9 (get index=1, slot=VALUE_SCALAR)
  jump to=L2
L10:
  set index=5, slot=VALUE_SCALAR (get index=3, slot=VALUE_SCALAR)
  jump to=L6
L2:
  set index=2, slot=VALUE_SCALAR (global context=4, name="b", slot=1)
  set index=3, slot=VALUE_SCALAR (get index=2, slot=VALUE_SCALAR)
  jump to=L3
L3:
  jump_if_true to=L10 (get index=3, slot=VALUE_SCALAR)
  jump to=L5
L5:
  set index=4, slot=VALUE_SCALAR (global context=4, name="c", slot=1)
  set index=5, slot=VALUE_SCALAR (get index=4, slot=VALUE_SCALAR)
  jump to=L6
L6:
  assign context=2 (global context=20, name="x", slot=1), (get index=5, slot=VALUE_SCALAR)
  jump to=L8
L8:
  end
L9:
  set index=3, slot=VALUE_SCALAR (get index=1, slot=VALUE_SCALAR)
  jump to=L3
EOI
