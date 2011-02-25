#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
bless $a, $b;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  bless context=2 (global context=4, name="a", slot=1), (global context=4, name="b", slot=1)
  jump to=L2
L2: # scope=0
  end
EOI
