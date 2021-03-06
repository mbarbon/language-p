#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub outer {
    return sub {
        3;
    };
}

$x = outer();
$y = sub {
    4
};
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign context=2 (call context=4 (make_array context=8), (global context=4, name="outer", slot=4)), (global context=20, name="x", slot=1)
  assign context=2 (make_closure (constant_sub value=anoncode)), (global context=20, name="y", slot=1)
  jump to=L2
L2: # scope=1
  end
# outer
L1: # scope=1
  lexical_state_set index=1
  return context=1 (make_closure (constant_sub value=anoncode))
# anoncode
L1: # scope=1
  lexical_state_set index=1
  return context=1 (constant_integer value=3)
# anoncode
L1: # scope=1
  lexical_state_set index=1
  return context=1 (constant_integer value=4)
EOI
