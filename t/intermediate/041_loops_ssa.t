#!/usr/bin/perl -w

use t::lib::TestIntermediate tests => 1;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub a {
    {
        last;
    }
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=1
  end
# a
L1: # scope=1
  lexical_state_set index=1
  jump to=L4
L4: # scope=1
  end
EOI
