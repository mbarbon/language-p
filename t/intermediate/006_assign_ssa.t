#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = @y
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  assign context=CXT_VOID (global context=CXT_SCALAR, name="y", slot=VALUE_ARRAY), (global context=CXT_SCALAR|CXT_LVALUE, name="x", slot=VALUE_SCALAR)
  jump to=L2
L2: # scope=0
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
L2: # scope=0
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
L2: # scope=0
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
L2: # scope=0
  end
EOI
