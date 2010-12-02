#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 8;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub is_scalar {
    print defined( wantarray ) && !wantarray ? "ok\n" : "not ok\n";
    return;
}
EOP
# main
L1:
  lexical_state_set index=0
  jump to=L2
L2:
  end
# is_scalar
L1:
  lexical_state_set index=1
  set index=1, slot=VALUE_HANDLE (global context=4, name="STDOUT", slot=VALUE_HANDLE)
  jump_if_true to=L5 (defined context=4 (want context=4))
  jump to=L7
L2:
  set index=5, slot=VALUE_SCALAR (phi L3, 2, VALUE_SCALAR, L4, 4, VALUE_SCALAR)
  set index=6, slot=VALUE_HANDLE (phi L3, 1, VALUE_HANDLE, L4, 3, VALUE_HANDLE)
  print context=2 (get index=6, slot=VALUE_HANDLE), (make_array context=8 (get index=5, slot=VALUE_SCALAR))
  return context=1 (make_list context=8)
L3:
  set index=2, slot=VALUE_SCALAR (constant_string value="ok\x0a")
  jump to=L2
L4:
  set index=3, slot=VALUE_HANDLE (get index=1, slot=VALUE_HANDLE)
  set index=4, slot=VALUE_SCALAR (constant_string value="not ok\x0a")
  jump to=L2
L5:
  jump_if_true to=L3 (not context=4 (want context=4))
  jump to=L8
L7:
  jump to=L4
L8:
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
L1:
  lexical_state_set index=0
  constant_integer value=1
  jump to=L5
L10:
  jump to=L4
L11:
  jump to=L5
L15:
  end
L16:
  jump to=L9
L17:
  jump to=L10
L4:
  constant_integer value=6
  jump to=L15
L5:
  jump_if_true to=L7 (constant_integer value=3)
  jump to=L16
L7:
  constant_integer value=2
  jump to=L9
L9:
  jump_if_true to=L11 (constant_integer value=4)
  jump to=L17
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub { xx( 123 ) if $_[0] }
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (make_closure (constant_sub value=anoncode))
  jump to=L2
L2:
  end
# anoncode
L1:
  lexical_state_set index=1
  jump to=L2
L2:
  jump_if_true to=L4 (array_element context=4, create=0 (constant_integer value=0), (lexical index=0, slot=2))
  jump to=L7
L3:
  end
L4:
  return context=1 (make_list context=8 (call context=1 (make_array context=8 (constant_integer value=123)), (global context=4, name="xx", slot=4)))
L7:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
while( 1 ) {
    1, last
}
EOP
# main
L1:
  lexical_state_set index=0
  jump to=L2
L2:
  jump_if_true to=L3 (constant_integer value=1)
  jump to=L7
L3:
  constant_integer value=1
  jump to=L5
L5:
  end
L7:
  jump to=L5
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x && do { $y }
EOP
# main
L1:
  lexical_state_set index=0
  set index=1, slot=VALUE_SCALAR (global context=4, name="x", slot=VALUE_SCALAR)
  jump_if_true to=L2 (get index=1, slot=VALUE_SCALAR)
  jump to=L4
L2:
  jump to=L5
L3:
  end
L4:
  jump to=L3
L5:
  global context=2, name="y", slot=1
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x ? do { $y } : $z
EOP
# main
L1:
  lexical_state_set index=0
  jump_if_true to=L3 (global context=4, name="x", slot=1)
  jump to=L4
L2:
  end
L3:
  global context=2, name="y", slot=1
  jump to=L2
L4:
  global context=2, name="z", slot=1
  jump to=L2
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub x {
    $x, return;
}
EOP
# main
L1:
  lexical_state_set index=0
  jump to=L2
L2:
  end
# x
L1:
  lexical_state_set index=1
  set index=1, slot=VALUE_SCALAR (global context=1, name="x", slot=VALUE_SCALAR)
  return context=1 (make_list context=8)
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
while( my( $k, $v ) = each %x ) {
    1;
}
EOP
# main
L1:
  lexical_state_set index=0
  jump to=L2
L2:
  jump_if_true to=L3 (assign context=4 (make_list context=24 (lexical_pad index=0, slot=1), (lexical_pad index=1, slot=1)), (each context=8 (global context=8, name="x", slot=3)))
  jump to=L5
L3:
  constant_integer value=1
  jump to=L2
L5:
  lexical_pad_clear index=1, slot=1
  lexical_pad_clear index=0, slot=1
  jump to=L6
L6:
  end
EOI
