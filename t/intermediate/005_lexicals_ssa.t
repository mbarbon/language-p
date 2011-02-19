#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 2;

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

generate_ssa_and_diff( <<'EOP', <<'EOI' );
my( @x, @y );
sub foo {
    my( $x, $y ) = @_;

    return $x ? @x : @y;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  make_list context=2 (lexical_pad index=0, slot=VALUE_ARRAY), (lexical_pad index=1, slot=VALUE_ARRAY)
  jump to=L2
L2: # scope=0
  end
# foo
L1: # scope=1
  lexical_state_set index=1
  assign context=2 (lexical index=0, slot=VALUE_ARRAY), (make_list context=24 (lexical index=1, slot=VALUE_SCALAR), (lexical index=2, slot=VALUE_SCALAR))
  jump_if_true to=L3 (lexical index=1, slot=VALUE_SCALAR)
  jump to=L4
L2: # scope=1
  set index=3, slot=VALUE_ARRAY (phi L3, 1, VALUE_ARRAY, L4, 2, VALUE_ARRAY)
  set index=4, slot=VALUE_ARRAY (make_list context=8 (get index=3, slot=VALUE_ARRAY))
  lexical_clear index=2, slot=VALUE_SCALAR
  lexical_clear index=1, slot=VALUE_SCALAR
  return context=1 (get index=4, slot=VALUE_ARRAY)
L3: # scope=1
  set index=1, slot=VALUE_ARRAY (lexical_pad index=0, slot=VALUE_ARRAY)
  jump to=L2
L4: # scope=1
  set index=2, slot=VALUE_ARRAY (lexical_pad index=1, slot=VALUE_ARRAY)
  jump to=L2
EOI
