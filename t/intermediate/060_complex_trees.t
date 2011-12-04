#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 3;

# value block as the first block of the scope
generate_linear_and_diff( <<'EOP', <<'EOI' );
sub foo {
    {
        my $caller = defined @{"x"} ? @{"y"} : 1;
    }

    1;
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
  jump to=L2
L2: # scope=3
  constant_string value="x"
  dereference_array context=CXT_SCALAR|CXT_NOCREATE
  defined context=CXT_SCALAR
  jump_if_true false=L7, true=L6
L4: # scope=1
  constant_integer value=1
  return context=CXT_CALLER
L5: # scope=2
  lexical lexical_info={index=1, slot=VALUE_SCALAR}
  assign context=CXT_VOID
  pop
  lexical_clear lexical_info={index=1, slot=VALUE_SCALAR}
  jump to=L4
L6: # scope=4
  constant_string value="y"
  dereference_array context=CXT_SCALAR
  jump to=L5
L7: # scope=2
  constant_integer value=1
  jump to=L5
EOI

# missing scope 3
generate_linear_and_diff( <<'EOP', <<'EOI' );
sub b {
    while( $a ) {
        if( $a ) {
            $f = 1;
        }
    }
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=1
  end
# b
L1: # scope=1
  lexical_state_set index=1
  jump to=L2
L10: # scope=4
  jump to=L2
L2: # scope=2
  global context=CXT_SCALAR, name="a", slot=VALUE_SCALAR
  jump_if_true false=L5, true=L7
L5: # scope=1
  end
L7: # scope=4
  global context=CXT_SCALAR, name="a", slot=VALUE_SCALAR
  jump_if_true false=L10, true=L8
L8: # scope=5
  constant_integer value=1
  global context=CXT_SCALAR|CXT_LVALUE, name="f", slot=1
  assign context=CXT_VOID
  pop
  jump to=L2
EOI

# nested conditional blocks
generate_linear_and_diff( <<'EOP', <<'EOI' );
sub he {
    if( $f ) {
	if( !$f ) {
	}
	my @f;
    }
}
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  jump to=L2
L2: # scope=1
  end
# he
L1: # scope=1
  lexical_state_set index=1
  jump to=L4
L2: # scope=1
  end
L4: # scope=2
  global context=CXT_SCALAR, name="f", slot=VALUE_SCALAR
  jump_if_true false=L2, true=L8
L7: # scope=3
  lexical lexical_info={index=1, slot=VALUE_ARRAY}
  lexical_clear lexical_info={index=1, slot=VALUE_ARRAY}
  return context=CXT_CALLER
L8: # scope=4
  global context=CXT_SCALAR, name="f", slot=VALUE_SCALAR
  not context=CXT_SCALAR
  jump_if_true false=L7, true=L7
EOI
