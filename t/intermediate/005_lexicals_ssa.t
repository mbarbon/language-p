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
  lexical_pad lexical_info={index=0, slot=VALUE_ARRAY}
  set index=1, slot=VALUE_ARRAY (lexical_pad lexical_info={index=0, slot=VALUE_ARRAY})
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
  make_list context=2 (lexical_pad lexical_info={index=0, slot=VALUE_ARRAY}), (lexical_pad lexical_info={index=1, slot=VALUE_ARRAY})
  jump to=L2
L2: # scope=0
  end
# foo
L1: # scope=1
  lexical_state_set index=1
  assign_list common=0, context=2 (lexical lexical_info={index=0, slot=VALUE_ARRAY}), (make_list context=24 (lexical lexical_info={index=1, slot=VALUE_SCALAR}), (lexical lexical_info={index=2, slot=VALUE_SCALAR}))
  jump_if_true false=L4, true=L3 (lexical lexical_info={index=1, slot=VALUE_SCALAR})
L2: # scope=1
  set index=3, slot=VALUE_ARRAY (phi blocks=[L3, L4], indices=[1, 2], slots=[VALUE_ARRAY, VALUE_ARRAY])
  lexical_clear lexical_info={index=2, slot=VALUE_SCALAR}
  lexical_clear lexical_info={index=1, slot=VALUE_SCALAR}
  return context=1 (get index=3, slot=VALUE_ARRAY)
L3: # scope=1
  set index=1, slot=VALUE_ARRAY (lexical_pad lexical_info={index=0, slot=VALUE_ARRAY})
  jump to=L2
L4: # scope=1
  set index=2, slot=VALUE_ARRAY (lexical_pad lexical_info={index=1, slot=VALUE_ARRAY})
  jump to=L2
EOI
