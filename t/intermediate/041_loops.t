#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 5;

generate_linear_and_diff( <<'EOP', <<'EOI' );
for( $i = 0; $i < 10; $i = $i + 1 ) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  constant_integer value=0
  global context=20, name="i", slot=1
  assign context=2
  pop
  jump to=L3
L3: # scope=2
  global context=4, name="i", slot=1
  constant_integer value=10
  jump_if_f_lt false=L6, true=L4
L4: # scope=3
  global context=4, name="STDOUT", slot=7
  global context=4, name="i", slot=1
  make_array arg_count=1, context=8
  print context=2
  pop
  jump to=L5
L5: # scope=2
  global context=4, name="i", slot=1
  constant_integer value=1
  add context=4
  global context=20, name="i", slot=1
  assign context=2
  pop
  jump to=L3
L6: # scope=1
  end
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
for(;;) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L4
L4: # scope=3
  global context=4, name="STDOUT", slot=7
  global context=4, name="i", slot=1
  make_array arg_count=1, context=8
  print context=2
  pop
  jump to=L4
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
for( $i = 0; ; $i = $i + 1 ) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  constant_integer value=0
  global context=20, name="i", slot=1
  assign context=2
  pop
  jump to=L4
L4: # scope=3
  global context=4, name="STDOUT", slot=7
  global context=4, name="i", slot=1
  make_array arg_count=1, context=8
  print context=2
  pop
  jump to=L5
L5: # scope=2
  global context=4, name="i", slot=1
  constant_integer value=1
  add context=4
  global context=20, name="i", slot=1
  assign context=2
  pop
  jump to=L4
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
for( $i = 0; $i < 10; $i = $i + 1 ) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  constant_integer value=0
  global context=20, name="i", slot=1
  assign context=2
  pop
  jump to=L3
L3: # scope=2
  global context=4, name="i", slot=1
  constant_integer value=10
  jump_if_f_lt false=L6, true=L4
L4: # scope=3
  global context=4, name="STDOUT", slot=7
  global context=4, name="i", slot=1
  make_array arg_count=1, context=8
  print context=2
  pop
  jump to=L5
L5: # scope=2
  global context=4, name="i", slot=1
  constant_integer value=1
  add context=4
  global context=20, name="i", slot=1
  assign context=2
  pop
  jump to=L3
L6: # scope=1
  end
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
for( my $i; $i; ++$i ) {
  print $i;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  lexical_pad lexical_info={index=0, slot=VALUE_SCALAR}
  pop
  jump to=L3
L3: # scope=2
  lexical_pad lexical_info={index=0, slot=VALUE_SCALAR}
  jump_if_true false=L6, true=L4
L4: # scope=3
  global context=CXT_SCALAR, name="STDOUT", slot=VALUE_HANDLE
  lexical_pad lexical_info={index=0, slot=VALUE_SCALAR}
  make_array arg_count=1, context=CXT_LIST
  print context=CXT_VOID
  pop
  jump to=L5
L5: # scope=2
  lexical_pad lexical_info={index=0, slot=VALUE_SCALAR}
  preinc context=CXT_VOID
  pop
  jump to=L3
L6: # scope=1
  lexical_pad_clear lexical_info={index=0, slot=VALUE_SCALAR}
  jump to=L7
L7: # scope=1
  end
EOI
