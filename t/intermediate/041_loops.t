#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_and_diff( <<'EOP', <<'EOI' );
for( $i = 0; $i < 10; $i = $i + 1 ) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L6
L2: # scope=1
  global context=4, name="i", slot=1
  constant_integer value=10
  jump_if_f_lt false=L5, true=L3
L3: # scope=3
  global context=4, name="STDOUT", slot=7
  global context=4, name="i", slot=1
  make_array arg_count=1, context=8
  print context=2
  pop
  jump to=L4
L4: # scope=1
  global context=4, name="i", slot=1
  constant_integer value=1
  add context=4
  global context=20, name="i", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L5: # scope=1
  end
L6: # scope=2
  constant_integer value=0
  global context=20, name="i", slot=1
  swap
  assign context=2
  pop
  jump to=L2
EOI

generate_and_diff( <<'EOP', <<'EOI' );
for(;;) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L3
L3: # scope=3
  global context=4, name="STDOUT", slot=7
  global context=4, name="i", slot=1
  make_array arg_count=1, context=8
  print context=2
  pop
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
for( $i = 0; ; $i = $i + 1 ) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L6
L3: # scope=3
  global context=4, name="STDOUT", slot=7
  global context=4, name="i", slot=1
  make_array arg_count=1, context=8
  print context=2
  pop
  jump to=L4
L4: # scope=1
  global context=4, name="i", slot=1
  constant_integer value=1
  add context=4
  global context=20, name="i", slot=1
  swap
  assign context=2
  pop
  jump to=L3
L6: # scope=2
  constant_integer value=0
  global context=20, name="i", slot=1
  swap
  assign context=2
  pop
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
for( $i = 0; $i < 10; $i = $i + 1 ) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L6
L2: # scope=1
  global context=4, name="i", slot=1
  constant_integer value=10
  jump_if_f_lt false=L5, true=L3
L3: # scope=3
  global context=4, name="STDOUT", slot=7
  global context=4, name="i", slot=1
  make_array arg_count=1, context=8
  print context=2
  pop
  jump to=L4
L4: # scope=1
  global context=4, name="i", slot=1
  constant_integer value=1
  add context=4
  global context=20, name="i", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L5: # scope=1
  end
L6: # scope=2
  constant_integer value=0
  global context=20, name="i", slot=1
  swap
  assign context=2
  pop
  jump to=L2
EOI
