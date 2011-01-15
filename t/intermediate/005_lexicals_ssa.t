#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
my @x;
push @x, @{$foo};
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  lexical_pad index=0, slot=VALUE_ARRAY
  set index=1, slot=VALUE_ARRAY (lexical_pad index=0, slot=VALUE_ARRAY)
  jump to=L2
L2: # scope=2
  array_push context=CXT_VOID (get index=1, slot=VALUE_ARRAY), (make_array context=CXT_LIST (dereference_array context=CXT_LIST (global context=CXT_SCALAR, name="foo", slot=VALUE_SCALAR)))
  jump to=L3
L3: # scope=0
  end
EOI
