#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
eval "1";
package x;
eval "2";
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  eval context=2, globals={}, hints=0, lexicals={}, package="main", warnings=undef (constant_string value="1")
  jump to=L2
L2: # scope=1
  lexical_state_set index=1
  eval context=2, globals={}, hints=0, lexicals={}, package="x", warnings=undef (constant_string value="2")
  jump to=L3
L3: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = eval {
    1;
    2;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  undef (global context=4, name="@", slot=1)
  constant_integer value=1
  set index=1, slot=VALUE_SCALAR (constant_integer value=2)
  undef (global context=4, name="@", slot=1)
  jump to=L4
L3: # scope=1
  set index=2, slot=VALUE_SCALAR (constant_undef)
  jump to=L4
L4: # scope=1
  set index=3, slot=VALUE_SCALAR (phi blocks=[L2, L3], indices=[1, 2], slots=[VALUE_SCALAR, VALUE_SCALAR])
  assign context=2 (get index=3, slot=VALUE_SCALAR), (global context=20, name="x", slot=1)
  jump to=L5
L5: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
eval {
    1;
    2;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  undef (global context=4, name="@", slot=1)
  constant_integer value=1
  constant_integer value=2
  undef (global context=4, name="@", slot=1)
  jump to=L4
L3: # scope=1
  jump to=L4
L4: # scope=1
  end
EOI
