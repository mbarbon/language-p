#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 2;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x =~ s/a/b/;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  rx_replace context=2, flags=0, index=1, to=L2 (global context=4, name="x", slot=1), (constant_regex value=anoncode)
  jump to=L3
L3: # scope=0
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $x =~ s/a/b/ ? 1 : 2;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=7 (global context=4, name="STDOUT", slot=7)
  jump_if_true to=L3 (rx_replace context=CXT_SCALAR, flags=0, index=1, to=L5 (global context=4, name="x", slot=1), (constant_regex value=anoncode))
  jump to=L4
L2: # scope=1
  set index=4, slot=VALUE_SCALAR (phi L3, 2, VALUE_SCALAR, L4, 3, VALUE_SCALAR)
  set index=5, slot=7 (get index=1, slot=7)
  print context=2 (get index=5, slot=7), (make_array context=8 (get index=4, slot=1))
  jump to=L6
L3: # scope=1
  set index=2, slot=1 (constant_integer value=1)
  jump to=L2
L4: # scope=1
  set index=3, slot=1 (constant_integer value=2)
  jump to=L2
L6: # scope=0
  end
EOI
