#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
defined $a[1];
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  defined context=CXT_VOID (array_element context=CXT_SCALAR, create=0 (constant_integer value=1), (global context=CXT_LIST, name="a", slot=VALUE_ARRAY))
  jump to=L2
L2: # scope=1
  end
EOI
