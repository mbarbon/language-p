#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 2;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
scalar $a;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  scalar context=CXT_VOID (global context=CXT_SCALAR, name="a", slot=VALUE_SCALAR)
  jump to=L2
L2: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
scalar( $a, $b, $c );
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  scalar context=CXT_VOID (make_list context=CXT_SCALAR (global context=CXT_VOID, name="a", slot=VALUE_SCALAR), (global context=CXT_VOID, name="b", slot=VALUE_SCALAR), (global context=CXT_SCALAR, name="c", slot=VALUE_SCALAR))
  jump to=L2
L2: # scope=1
  end
EOI
