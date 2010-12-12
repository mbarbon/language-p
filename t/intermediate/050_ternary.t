#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b : $c + 3;
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="a", slot=1
  constant_integer value=2
  jump_if_f_gt false=L4, true=L3
L2:
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L5
L3:
  global context=4, name="b", slot=1
  jump to=L2
L4:
  global context=4, name="c", slot=1
  constant_integer value=3
  add context=4
  jump to=L2
L5:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$a ? $b : $c
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="a", slot=1
  jump_if_true false=L4, true=L3
L2:
  end
L3:
  global context=2, name="b", slot=1
  pop
  jump to=L2
L4:
  global context=2, name="c", slot=1
  pop
  jump to=L2
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b :
     $c < 3 ? $d : $e;
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="a", slot=1
  constant_integer value=2
  jump_if_f_gt false=L4, true=L3
L2:
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L8
L3:
  global context=4, name="b", slot=1
  jump to=L2
L4:
  global context=4, name="c", slot=1
  constant_integer value=3
  jump_if_f_lt false=L7, true=L6
L6:
  global context=4, name="d", slot=1
  jump to=L2
L7:
  global context=4, name="e", slot=1
  jump to=L2
L8:
  end
EOI
