#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
2 and last while 1
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=1
  jump_if_true false=L9, true=L3 (constant_integer value=1)
L3: # scope=1
  set index=1, slot=VALUE_SCALAR (constant_integer value=2)
  jump_if_true false=L8, true=L6 (get index=1, slot=VALUE_SCALAR)
L5: # scope=1
  end
L6: # scope=1
  jump to=L5
L8: # scope=1
  jump to=L2
L9: # scope=1
  jump to=L5
EOI
