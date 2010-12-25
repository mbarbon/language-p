#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 6;

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L6, true=L2
L2:
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3:
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L5
L5:
  end
L6:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L2, true=L6
L2:
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3:
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L5
L5:
  end
L6:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$a && $b && $c;
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L8, true=L2
L2:
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3:
  dup
  jump_if_true false=L7, true=L5
L5:
  pop
  global context=2, name="c", slot=1
  pop
  jump to=L6
L6:
  end
L7:
  pop
  jump to=L6
L8:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L9, true=L2
L10:
  jump to=L6
L2:
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3:
  dup
  jump_if_true false=L10, true=L5
L5:
  pop
  global context=4, name="c", slot=1
  jump to=L6
L6:
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L8
L8:
  end
L9:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L2, true=L9
L10:
  jump to=L6
L2:
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3:
  dup
  jump_if_true false=L5, true=L10
L5:
  pop
  global context=4, name="c", slot=1
  jump to=L6
L6:
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L8
L8:
  end
L9:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x &&= $a;
EOP
# main
L1:
  lexical_state_set index=0
  global context=20, name="x", slot=1
  dup
  jump_if_true false=L4, true=L2
L2:
  global context=4, name="a", slot=1
  assign context=2
  pop
  jump to=L3
L3:
  end
L4:
  pop
  jump to=L3
EOI
