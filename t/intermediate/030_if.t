#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 5;

generate_and_diff( <<'EOP', <<'EOI' );
0;
unless( $a < 2 ) {
    1;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  constant_integer value=0
  pop
  jump to=L4
L2: # scope=1
  end
L4: # scope=2
  global context=4, name="a", slot=1
  constant_integer value=2
  jump_if_f_lt false=L5, true=L7
L5: # scope=3
  constant_integer value=1
  pop
  jump to=L2
L7: # scope=0
  jump to=L2
EOI

generate_and_diff( <<'EOP', <<'EOI' );
0;
if( $a < 11 ) {
    1
} elsif( $a < 12 ) {
    2
} else {
    3
}
4;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  constant_integer value=0
  pop
  jump to=L4
L2: # scope=1
  constant_integer value=4
  pop
  jump to=L9
L4: # scope=2
  global context=4, name="a", slot=1
  constant_integer value=11
  jump_if_f_lt false=L6, true=L5
L5: # scope=3
  constant_integer value=1
  pop
  jump to=L2
L6: # scope=2
  global context=4, name="a", slot=1
  constant_integer value=12
  jump_if_f_lt false=L8, true=L7
L7: # scope=4
  constant_integer value=2
  pop
  jump to=L2
L8: # scope=5
  constant_integer value=3
  pop
  jump to=L2
L9: # scope=0
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
0;
if( $a - 1 ) {
    1
}
2;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  constant_integer value=0
  pop
  jump to=L4
L2: # scope=1
  constant_integer value=2
  pop
  jump to=L7
L4: # scope=2
  global context=4, name="a", slot=1
  constant_integer value=1
  subtract context=4
  jump_if_true false=L8, true=L5
L5: # scope=3
  constant_integer value=1
  pop
  jump to=L2
L7: # scope=0
  end
L8: # scope=0
  jump to=L2
EOI

generate_and_diff( <<'EOP', <<'EOI' );
0;
if( $a && $b ) {
    1
}
2;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  constant_integer value=0
  pop
  jump to=L4
L10: # scope=0
  jump to=L2
L2: # scope=1
  constant_integer value=2
  pop
  jump to=L8
L4: # scope=2
  global context=4, name="a", slot=1
  jump_if_true false=L9, true=L7
L5: # scope=3
  constant_integer value=1
  pop
  jump to=L2
L7: # scope=2
  global context=4, name="b", slot=1
  jump_if_true false=L10, true=L5
L8: # scope=0
  end
L9: # scope=0
  jump to=L2
EOI

generate_and_diff( <<'EOP', <<'EOI' );
if( $y eq '' ) {
    3 unless $z;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L4
L11: # scope=0
  jump to=L2
L12: # scope=0
  jump to=L2
L2: # scope=1
  end
L4: # scope=2
  global context=4, name="y", slot=1
  constant_string value=""
  jump_if_s_eq false=L11, true=L8
L8: # scope=3
  global context=4, name="z", slot=1
  jump_if_true false=L9, true=L12
L9: # scope=3
  constant_integer value=3
  pop
  jump to=L2
EOI
