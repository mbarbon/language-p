#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x =~ tr/a/b/;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  rx_transliterate context=2, flags=0, match="a", replacement="b" (global context=4, name="x", slot=1)
  jump to=L2
L2: # scope=0
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $x =~ tr/a/b/ ? 1 : 2;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=7 (global context=4, name="STDOUT", slot=7)
  jump_if_true false=L4, true=L3 (rx_transliterate context=4, flags=0, match="a", replacement="b" (global context=4, name="x", slot=1))
L2: # scope=1
  set index=4, slot=1 (phi L3, 2, 1, L4, 3, 1)
  print context=2 (get index=1, slot=7), (make_array context=8 (get index=4, slot=1))
  jump to=L5
L3: # scope=1
  set index=2, slot=1 (constant_integer value=1)
  jump to=L2
L4: # scope=1
  set index=3, slot=1 (constant_integer value=2)
  jump to=L2
L5: # scope=0
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$b !~ tr/a/b/
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  not context=2 (rx_transliterate context=2, flags=0, match="a", replacement="b" (global context=4, name="b", slot=1))
  jump to=L2
L2: # scope=0
  end
EOI
