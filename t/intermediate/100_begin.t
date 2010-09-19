#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
1;
BEGIN {
    3;
}
2;
EOP
# main
L1:
  constant_integer value=1
  constant_integer value=2
  jump to=L2
L2:
  end
# BEGIN
L1:
  lexical_state_set index=1
  return context=1 (make_array (constant_integer value=3))
  jump to=L2
L2:
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
use Foo (1, 2);

1;
EOP
# main
L1:
  constant_integer value=1
  jump to=L2
L2:
  end
# BEGIN
L1:
  lexical_state_set index=1
  require_file context=2 (constant_string value="Foo.pm")
  set index=1 (find_method method="import" (constant_string value="Foo"))
  set index=2 (make_array (constant_string value="Foo"), (constant_integer value=1), (constant_integer value=2))
  jump_if_null to=L2 (get index=1)
  jump to=L3
L2:
  jump to=L4
L3:
  call context=2 (get index=2), (get index=1)
  jump to=L4
L4:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
use 5;
EOP
# main
L1:
  end
# BEGIN
L1:
  lexical_state_set index=1
  constant_integer value=5
  global context=4, name="]", slot=1
  jump_if_f_lt false=L3, true=L4
L3:
  fresh_string value="Perl "
  constant_float value=5
  constant_string value=" required--this is only "
  global context=4, name="]", slot=1
  constant_string value=", stopped"
  concat
  concat
  concat
  concat
  make_array context=8, count=1
  die
  pop
  jump to=L4
L4:
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
use 5;
EOP
# main
L1:
  end
# BEGIN
L1:
  lexical_state_set index=1
  jump_if_f_lt to=L4 (constant_integer value=5), (global context=4, name="]", slot=1)
  jump to=L3
L3:
  die (make_array (concat (fresh_string value="Perl "), (concat (constant_float value=5), (concat (constant_string value=" required--this is only "), (concat (global context=4, name="]", slot=1), (constant_string value=", stopped"))))))
  jump to=L4
L4:
  end
EOI
