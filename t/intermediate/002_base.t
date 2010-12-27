#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a + 2
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="a", slot=1
  constant_integer value=2
  add context=4
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
print !$a
EOP
# main
L1:
  lexical_state_set index=0
  global context=4, name="STDOUT", slot=7
  global context=4, name="a", slot=1
  not context=8
  make_array arg_count=1, context=8
  print context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = "$a\n";
EOP
# main
L1:
  lexical_state_set index=0
  fresh_string value=""
  global context=4, name="a", slot=1
  concat_assign context=4
  constant_string value="\x0a"
  concat_assign context=4
  global context=20, name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L2:
  end
EOI
