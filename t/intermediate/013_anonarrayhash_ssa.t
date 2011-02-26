#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 2;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = [ 1, 2, 3 ];
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign context=2 (anonymous_array (make_list context=8 (constant_integer value=1), (constant_integer value=2), (constant_integer value=3))), (global context=20, name="x", slot=1)
  jump to=L2
L2: # scope=0
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = { a => 1, b => 2 };
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign context=2 (anonymous_hash (make_list context=8 (constant_string value="a"), (constant_integer value=1), (constant_string value="b"), (constant_integer value=2))), (global context=20, name="x", slot=1)
  jump to=L2
L2: # scope=0
  end
EOI
