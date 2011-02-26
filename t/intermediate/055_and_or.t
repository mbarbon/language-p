#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 6;

generate_linear_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L4, true=L2
L2: # scope=1
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3: # scope=1
  global context=20, name="x", slot=1
  assign context=2
  pop
  jump to=L5
L4: # scope=1
  jump to=L3
L5: # scope=0
  end
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L2, true=L4
L2: # scope=1
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3: # scope=1
  global context=20, name="x", slot=1
  assign context=2
  pop
  jump to=L5
L4: # scope=1
  jump to=L3
L5: # scope=0
  end
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
$a && $b && $c;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L4, true=L2
L2: # scope=1
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3: # scope=1
  dup
  jump_if_true false=L7, true=L5
L4: # scope=1
  jump to=L3
L5: # scope=1
  pop
  global context=2, name="c", slot=1
  pop
  jump to=L6
L6: # scope=1
  end
L7: # scope=1
  pop
  jump to=L6
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L4, true=L2
L2: # scope=1
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3: # scope=1
  dup
  jump_if_true false=L7, true=L5
L4: # scope=1
  jump to=L3
L5: # scope=1
  pop
  global context=4, name="c", slot=1
  jump to=L6
L6: # scope=1
  global context=20, name="x", slot=1
  assign context=2
  pop
  jump to=L8
L7: # scope=1
  jump to=L6
L8: # scope=0
  end
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  global context=4, name="a", slot=1
  dup
  jump_if_true false=L2, true=L4
L2: # scope=1
  pop
  global context=4, name="b", slot=1
  jump to=L3
L3: # scope=1
  dup
  jump_if_true false=L5, true=L7
L4: # scope=1
  jump to=L3
L5: # scope=1
  pop
  global context=4, name="c", slot=1
  jump to=L6
L6: # scope=1
  global context=20, name="x", slot=1
  assign context=2
  pop
  jump to=L8
L7: # scope=1
  jump to=L6
L8: # scope=0
  end
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
$x &&= $a;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  global context=20, name="x", slot=1
  dup
  jump_if_true false=L4, true=L2
L2: # scope=1
  global context=4, name="a", slot=1
  swap_assign context=2
  pop
  jump to=L3
L3: # scope=1
  end
L4: # scope=1
  pop
  jump to=L3
EOI
