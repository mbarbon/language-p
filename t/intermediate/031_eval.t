#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_linear_and_diff( <<'EOP', <<'EOI' );
eval "1";
package x;
eval "2";
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  constant_string value="1"
  eval context=2, globals={}, hints=0, lexicals={}, package="main", warnings=undef
  pop
  jump to=L2
L2: # scope=1
  lexical_state_set index=1
  constant_string value="2"
  eval context=2, globals={}, hints=0, lexicals={}, package="x", warnings=undef
  pop
  jump to=L3
L3: # scope=1
  end
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
$x = eval { 1 };
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  global context=4, name="@", slot=1
  undef
  constant_integer value=1
  global context=4, name="@", slot=1
  undef
  jump to=L4
L3: # scope=1
  constant_undef
  jump to=L4
L4: # scope=1
  global context=20, name="x", slot=1
  assign context=2
  pop
  jump to=L5
L5: # scope=1
  end
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
eval {
    package x;
    2
};
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  lexical_state_save index=0
  global context=4, name="@", slot=1
  undef
  jump to=L3
L3: # scope=2
  lexical_state_set index=1
  constant_integer value=2
  pop
  lexical_state_restore index=0
  global context=4, name="@", slot=1
  undef
  jump to=L5
L4: # scope=1
  jump to=L5
L5: # scope=1
  end
EOI
