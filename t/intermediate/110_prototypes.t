#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_and_diff( <<'EOP', <<'EOI' );
push @foo, 1, 2;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  global context=8, name="foo", slot=2
  constant_integer value=1
  constant_integer value=2
  make_array arg_count=2, context=8
  array_push context=2
  pop
  jump to=L2
L2: # scope=0
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
pop @foo;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  global context=8, name="foo", slot=2
  array_pop context=2
  pop
  jump to=L2
L2: # scope=0
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
sub mypush(\@@);

mypush @foo, 1, 2;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  global context=8, name="foo", slot=2
  reference
  constant_integer value=1
  constant_integer value=2
  make_array arg_count=3, context=8
  global context=4, name="mypush", slot=4
  call context=2
  pop
  jump to=L2
L2: # scope=0
  end
EOI
