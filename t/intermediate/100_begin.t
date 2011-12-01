#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 5;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
1;
BEGIN {
    3;
}
2;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  constant_integer value=1
  constant_integer value=2
  jump to=L2
L2: # scope=1
  end
# BEGIN
L1: # scope=1
  lexical_state_set index=1
  return context=1 (constant_integer value=3)
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
1;
package X;

BEGIN {
    3;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  constant_integer value=1
  jump to=L2
L2: # scope=1
  lexical_state_set index=1
  jump to=L3
L3: # scope=1
  end
# X::BEGIN
L1: # scope=1
  lexical_state_set index=1
  return context=1 (constant_integer value=3)
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
use Foo (1, 2);

1;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  constant_integer value=1
  jump to=L2
L2: # scope=1
  end
# BEGIN
L1: # scope=1
  lexical_state_set index=1
  require_file context=2 (constant_string value="Foo.pm")
  set index=1, slot=VALUE_ARRAY (make_array context=8 (constant_string value="Foo"), (constant_integer value=1), (constant_integer value=2))
  set index=2, slot=VALUE_SUB (find_method context=CXT_SCALAR, method="import" (constant_string value="Foo"))
  jump_if_null false=L3, true=L2 (get index=2, slot=VALUE_SUB)
L2: # scope=1
  jump to=L4
L3: # scope=1
  call context=2 (get index=1, slot=VALUE_ARRAY), (get index=2, slot=VALUE_SUB)
  jump to=L4
L4: # scope=1
  end
EOI

generate_linear_and_diff( <<'EOP', <<'EOI' );
use 5;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=1
  end
# BEGIN
L1: # scope=1
  lexical_state_set index=1
  constant_float value=5
  global context=4, name="]", slot=1
  jump_if_f_lt false=L3, true=L5
L3: # scope=1
  fresh_string value="Perl "
  constant_float value=5
  constant_string value=" required--this is only "
  global context=4, name="]", slot=1
  constant_string value=", stopped"
  make_array arg_count=5, context=8
  die context=2
  pop
  jump to=L4
L4: # scope=1
  end
L5: # scope=1
  jump to=L4
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
use 5;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=1
  end
# BEGIN
L1: # scope=1
  lexical_state_set index=1
  jump_if_f_lt false=L3, true=L5 (constant_float value=5), (global context=4, name="]", slot=1)
L3: # scope=1
  die context=2 (make_array context=8 (fresh_string value="Perl "), (constant_float value=5), (constant_string value=" required--this is only "), (global context=4, name="]", slot=1), (constant_string value=", stopped"))
  jump to=L4
L4: # scope=1
  end
L5: # scope=1
  jump to=L4
EOI
