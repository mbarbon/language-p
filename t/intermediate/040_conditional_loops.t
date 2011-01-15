#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_and_diff( <<'EOP', <<'EOI' );
while( $a ) {
    1;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  global context=4, name="a", slot=1
  jump_if_true false=L5, true=L3
L3: # scope=3
  constant_integer value=1
  pop
  jump to=L2
L5: # scope=1
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
2 and last while 1
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L10: # scope=0
  jump to=L5
L2: # scope=1
  constant_integer value=1
  jump_if_true false=L10, true=L3
L3: # scope=1
  constant_integer value=2
  dup
  jump_if_true false=L8, true=L6
L5: # scope=1
  end
L6: # scope=1
  pop
  discard_stack
  jump to=L5
L8: # scope=1
  pop
  jump to=L2
EOI

generate_and_diff( <<'EOP', <<'EOI' );
until( $a ) {
    1;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  global context=4, name="a", slot=1
  jump_if_true false=L3, true=L5
L3: # scope=3
  constant_integer value=1
  pop
  jump to=L2
L5: # scope=1
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
2 and last while 1
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L10: # scope=0
  jump to=L5
L2: # scope=1
  constant_integer value=1
  jump_if_true false=L10, true=L3
L3: # scope=1
  constant_integer value=2
  dup
  jump_if_true false=L8, true=L6
L5: # scope=1
  end
L6: # scope=1
  pop
  discard_stack
  jump to=L5
L8: # scope=1
  pop
  jump to=L2
EOI
