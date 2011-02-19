#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a + 2;
print !$a
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign context=2 (add context=4 (global context=4, name="a", slot=1), (constant_integer value=2)), (global context=20, name="x", slot=1)
  print context=2 (global context=4, name="STDOUT", slot=7), (make_array context=8 (not context=8 (global context=4, name="a", slot=1)))
  jump to=L2
L2: # scope=0
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = abs $t;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign context=2 (abs context=4 (global context=4, name="t", slot=1)), (global context=20, name="x", slot=1)
  jump to=L2
L2: # scope=0
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = "$a\n";
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign context=2 (concat_assign context=4 (concat_assign context=4 (fresh_string value=""), (global context=4, name="a", slot=1)), (constant_string value="\x0a")), (global context=20, name="x", slot=1)
  jump to=L2
L2: # scope=0
  end
EOI
