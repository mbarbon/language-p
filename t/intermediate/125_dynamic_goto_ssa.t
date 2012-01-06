#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_ssa_and_diff( <<'EOP', <<'EOI' );
goto &foo;
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  dynamic_goto context=CXT_VOID (reference context=CXT_SCALAR (global context=CXT_SCALAR|CXT_LVALUE, name="foo", slot=4))
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
goto &{foo()};
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=2
  dynamic_goto context=CXT_VOID (reference context=CXT_SCALAR (dereference_subroutine context=CXT_SCALAR|CXT_LVALUE (call context=CXT_SCALAR (make_array context=CXT_LIST), (global context=CXT_SCALAR, name="foo", slot=VALUE_SUB))))
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
L2: # scope=1
  end
# foo
L1: # scope=1
  lexical_state_set index=1
  dynamic_goto context=CXT_CALLER (reference context=CXT_SCALAR (global context=CXT_SCALAR|CXT_LVALUE, name="foo", slot=VALUE_SUB))
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
L2: # scope=1
  end
# foo
L1: # scope=1
  lexical_state_set index=1
  jump to=L3
L2: # scope=1
  end
L3: # scope=1
  jump_if_true false=L2, true=L4 (global context=CXT_SCALAR, name="a", slot=VALUE_SCALAR)
L4: # scope=1
  dynamic_goto context=CXT_CALLER (reference context=CXT_SCALAR (global context=CXT_SCALAR|CXT_LVALUE, name="foo", slot=VALUE_SUB))
EOI
