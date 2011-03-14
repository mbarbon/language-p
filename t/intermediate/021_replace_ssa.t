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
L2: # scope=2
  stop (constant_string value="b")
L3: # scope=0
  end
# anoncode
L1: # scope=0
  rx_start_match
  rx_exact characters="a", length=1
  rx_accept groups=0
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $x =~ s/a/b/ ? 1 : 2;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=7 (global context=4, name="STDOUT", slot=7)
  jump_if_true false=L4, true=L3 (rx_replace context=CXT_SCALAR, flags=0, index=1, to=L5 (global context=4, name="x", slot=1), (constant_regex value=anoncode))
L2: # scope=1
  set index=4, slot=VALUE_SCALAR (phi blocks=[L3, L4], indices=[2, 3], slots=[VALUE_SCALAR, VALUE_SCALAR])
  print context=2 (get index=1, slot=7), (make_array context=8 (get index=4, slot=1))
  jump to=L6
L3: # scope=1
  set index=2, slot=1 (constant_integer value=1)
  jump to=L2
L4: # scope=1
  set index=3, slot=1 (constant_integer value=2)
  jump to=L2
L5: # scope=2
  stop (constant_string value="b")
L6: # scope=0
  end
# anoncode
L1: # scope=0
  rx_start_match
  rx_exact characters="a", length=1
  rx_accept groups=0
EOI
