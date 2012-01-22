#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
exists $a[1];
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  exists_array context=CXT_VOID (global context=CXT_LIST, name="a", slot=VALUE_ARRAY), (constant_integer value=1)
  jump to=L2
L2: # scope=1
  end
EOI
