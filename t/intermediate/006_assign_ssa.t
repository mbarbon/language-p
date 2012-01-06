#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 6;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = @y
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign context=CXT_VOID (global context=CXT_SCALAR, name="y", slot=VALUE_ARRAY), (global context=CXT_SCALAR|CXT_LVALUE, name="x", slot=VALUE_SCALAR)
  jump to=L2
L2: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
@x = $y
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign_list common=0, context=CXT_VOID (global context=CXT_SCALAR, name="y", slot=VALUE_SCALAR), (global context=CXT_LIST|CXT_LVALUE, name="x", slot=VALUE_ARRAY)
  jump to=L2
L2: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
( $x ) = @y
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign_list common=0, context=CXT_VOID (global context=CXT_LIST, name="y", slot=VALUE_ARRAY), (make_list context=CXT_LIST|CXT_LVALUE (global context=CXT_SCALAR|CXT_LVALUE, name="x", slot=VALUE_SCALAR))
  jump to=L2
L2: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
@$x = $y
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign_list common=1, context=CXT_VOID (global context=CXT_SCALAR, name="y", slot=VALUE_SCALAR), (vivify_array context=CXT_LIST|CXT_LVALUE (global context=CXT_SCALAR, name="x", slot=VALUE_SCALAR))
  jump to=L2
L2: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x[0] = 1
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign context=CXT_VOID (constant_integer value=1), (array_element context=CXT_SCALAR, create=1 (constant_integer value=0), (global context=CXT_LIST|CXT_LVALUE, name="x", slot=VALUE_ARRAY))
  jump to=L2
L2: # scope=1
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
foo( $x[0] );
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  call context=CXT_VOID (make_array context=CXT_LIST (array_element context=CXT_LIST, create=2 (constant_integer value=0), (global context=CXT_LIST, name="x", slot=VALUE_ARRAY))), (global context=CXT_SCALAR, name="foo", slot=VALUE_SUB)
  jump to=L2
L2: # scope=1
  end
EOI
