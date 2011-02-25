#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
goto &foo;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  dynamic_goto context=2 (reference context=4 (global context=4, name="foo", slot=4))
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
goto &{foo()};
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  dynamic_goto context=2 (reference context=4 (dereference_subroutine context=4 (call context=4 (make_array context=8), (global context=4, name="foo", slot=4))))
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub foo {
    goto &foo;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=0
  end
# foo
L1: # scope=1
  lexical_state_set index=1
  dynamic_goto context=1 (reference context=4 (global context=4, name="foo", slot=4))
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub foo {
    goto &foo if $a;
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=0
  end
# foo
L1: # scope=1
  lexical_state_set index=1
  jump to=L3
L2: # scope=1
  end
L3: # scope=1
  jump_if_true false=L2, true=L4 (global context=4, name="a", slot=1)
L4: # scope=1
  dynamic_goto context=1 (reference context=4 (global context=4, name="foo", slot=4))
EOI
