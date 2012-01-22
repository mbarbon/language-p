#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 12;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub is_scalar {
    print defined( wantarray ) && !wantarray ? "ok\n" : "not ok\n";
    return;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=1
  end
# is_scalar
L1: # scope=1
  lexical_state_set index=1
  set index=1, slot=VALUE_HANDLE (global context=4, name="STDOUT", slot=VALUE_HANDLE)
  jump_if_true false=L6, true=L5 (defined context=4 (want context=4))
L2: # scope=1
  set index=4, slot=VALUE_SCALAR (phi blocks=[L3, L4], indices=[2, 3], slots=[VALUE_SCALAR, VALUE_SCALAR])
  print context=2 (get index=1, slot=VALUE_HANDLE), (make_array context=8 (get index=4, slot=VALUE_SCALAR))
  return context=1 (make_list context=8)
L3: # scope=1
  set index=2, slot=VALUE_SCALAR (constant_string value="ok\x0a")
  jump to=L2
L4: # scope=1
  set index=3, slot=VALUE_SCALAR (constant_string value="not ok\x0a")
  jump to=L2
L5: # scope=1
  jump_if_true false=L7, true=L3 (not context=4 (want context=4))
L6: # scope=1
  jump to=L4
L7: # scope=1
  jump to=L4
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
1;
{
    2 if 3;
    redo if 4;
    last;
    7;
} continue {
    5;
}
6;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  constant_integer value=1
  jump to=L6
L11: # scope=2
  jump_if_true false=L14, true=L16 (constant_integer value=4)
L14: # scope=2
  jump to=L4
L15: # scope=1
  end
L16: # scope=2
  jump to=L6
L4: # scope=1
  constant_integer value=6
  jump to=L15
L6: # scope=2
  jump_if_true false=L9, true=L7 (constant_integer value=3)
L7: # scope=2
  constant_integer value=2
  jump to=L11
L9: # scope=2
  jump to=L11
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub { xx( 123 ) if $_[0] }
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (make_closure (constant_sub value=anoncode))
  jump to=L2
L2: # scope=1
  end
# anoncode
L1: # scope=1
  lexical_state_set index=1
  jump to=L3
L2: # scope=1
  end
L3: # scope=1
  jump_if_true false=L2, true=L4 (array_element context=4, create=0 (lexical lexical_info={index=0, slot=VALUE_ARRAY}), (constant_integer value=0))
L4: # scope=1
  return context=1 (call context=1 (make_array context=8 (constant_integer value=123)), (global context=4, name="xx", slot=4))
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
while( 1 ) {
    1, last
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  jump_if_true false=L6, true=L3 (constant_integer value=1)
L3: # scope=3
  constant_integer value=1
  jump to=L5
L5: # scope=1
  end
L6: # scope=2
  jump to=L5
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x && do { $y }
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="x", slot=VALUE_SCALAR)
  jump_if_true false=L4, true=L2 (get index=1, slot=VALUE_SCALAR)
L2: # scope=2
  global context=2, name="y", slot=1
  jump to=L3
L3: # scope=1
  end
L4: # scope=1
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x ? do { $y } : $z
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump_if_true false=L4, true=L3 (global context=4, name="x", slot=1)
L2: # scope=1
  end
L3: # scope=2
  global context=2, name="y", slot=1
  jump to=L2
L4: # scope=1
  set index=1, slot=1 (global context=2, name="z", slot=1)
  jump to=L2
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub x {
    $x, return;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=1
  end
# x
L1: # scope=1
  lexical_state_set index=1
  global context=1, name="x", slot=VALUE_SCALAR
  return context=1 (make_list context=8)
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
while( my( $k, $v ) = each %x ) {
    1;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  jump_if_true false=L5, true=L3 (assign_list common=1, context=4 (each context=8 (global context=8, name="x", slot=3)), (make_list context=24 (lexical_pad lexical_info={index=0, slot=VALUE_SCALAR}), (lexical_pad lexical_info={index=1, slot=VALUE_SCALAR})))
L3: # scope=3
  constant_integer value=1
  jump to=L2
L5: # scope=1
  lexical_pad_clear lexical_info={index=1, slot=VALUE_SCALAR}
  lexical_pad_clear lexical_info={index=0, slot=VALUE_SCALAR}
  jump to=L6
L6: # scope=1
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
2 and $$_ =~ s/// and 1;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  set index=1, slot=1 (constant_integer value=2)
  jump_if_true to=L2 (get index=1, slot=1)
  jump to=L4
L2: # scope=1
  set index=2, slot=1 (rx_replace context=4, flags=0, index=1, to=L5 (dereference_scalar context=4 (global context=4, name="_", slot=1)), (constant_regex value=anoncode))
  jump to=L6
L3: # scope=1
  jump_if_true to=L7 (get index=3, slot=1)
  jump to=L9
L4: # scope=1
  set index=3, slot=1 (get index=1, slot=1)
  jump to=L3
L5: # scope=2
  stop (constant_string value="")
L6: # scope=1
  set index=3, slot=1 (get index=2, slot=1)
  jump to=L3
L7: # scope=1
  constant_integer value=1
  jump to=L8
L8: # scope=1
  end
L9: # scope=1
  jump to=L8
# anoncode
L1: # scope=0
  rx_start_match
  rx_accept groups=0
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
for $r ( 13, 14 ) {
    print $r ? "ok $r\n" : "not ok\n";
}
my $r = 8;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L10: # scope=3
  set index=3, slot=1 (concat_assign context=4 (concat_assign context=4 (concat_assign context=4 (fresh_string value=""), (constant_string value="ok ")), (global context=4, name="r", slot=1)), (constant_string value="\x0a"))
  jump to=L9
L11: # scope=3
  set index=4, slot=1 (constant_string value="not ok\x0a")
  jump to=L9
L12: # scope=1
  assign context=2 (constant_integer value=8), (lexical_pad lexical_info={index=0, slot=1})
  jump to=L13
L13: # scope=1
  end
L2: # scope=2
  temporary_set index=0, slot=9 (iterator (make_list context=8 (constant_integer value=13), (constant_integer value=14)))
  temporary_set index=1, slot=5 (global context=4, name="r", slot=5)
  localize_glob_slot index=2, name="r", slot=1
  jump to=L3
L3: # scope=2
  set index=1, slot=1 (iterator_next (temporary index=0, slot=9))
  jump_if_null false=L4, true=L6 (get index=1, slot=1)
L4: # scope=2
  swap_glob_slot_set slot=1 (get index=1, slot=1), (temporary index=1, slot=5)
  jump to=L8
L6: # scope=2
  jump to=L7
L7: # scope=1
  temporary_clear index=1, slot=5
  restore_glob_slot index=2, name="r", slot=1
  jump to=L12
L8: # scope=3
  set index=2, slot=7 (global context=4, name="STDOUT", slot=7)
  jump_if_true false=L11, true=L10 (global context=4, name="r", slot=1)
L9: # scope=3
  set index=5, slot=1 (phi blocks=[L10, L11], indices=[3, 4], slots=[1, 1])
  print context=2 (get index=2, slot=7), (make_array context=8 (get index=5, slot=1))
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
while( $i < 0 ) {
    2;
}

while( $i < 3 ) {
    4;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L10: # scope=2
  jump to=L6
L2: # scope=2
  jump_if_f_lt false=L10, true=L3 (global context=CXT_SCALAR, name="i", slot=VALUE_SCALAR), (constant_integer value=0)
L3: # scope=3
  constant_integer value=2
  jump to=L2
L6: # scope=4
  jump_if_f_lt false=L9, true=L7 (global context=CXT_SCALAR, name="i", slot=VALUE_SCALAR), (constant_integer value=3)
L7: # scope=5
  constant_integer value=4
  jump to=L6
L9: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
while( do { my $c; 0 } ) {
    1;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=3
  lexical_pad lexical_info={index=0, slot=VALUE_SCALAR}
  set index=1, slot=VALUE_SCALAR (constant_integer value=0)
  lexical_pad_clear lexical_info={index=0, slot=VALUE_SCALAR}
  jump_if_true false=L5, true=L3 (get index=1, slot=VALUE_SCALAR)
L3: # scope=4
  constant_integer value=1
  jump to=L2
L5: # scope=1
  end
EOI
