#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub is_scalar {
    print defined( wantarray ) && !wantarray ? "ok\n" : "not ok\n";
    return;
}
EOP
# main
L1:
  end
# is_scalar
L1:
  lexical_state_set index=1
  set index=1 (global context=4, name="STDOUT", slot=7)
  jump_if_true to=L5 (defined context=4 (want context=4))
  jump to=L7
L2:
  set index=4 (phi L3, 2, L4, 3)
  print context=2 (get index=1), (make_array context=8 (get index=4))
  return context=1 (make_array context=8)
  jump to=L6
L3:
  set index=2 (constant_string value="ok\x0a")
  jump to=L2
L4:
  set index=3 (constant_string value="not ok\x0a")
  jump to=L2
L5:
  jump_if_true to=L3 (not context=4 (want context=4))
  jump to=L8
L6:
  end
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
  constant_integer value=1
  jump to=L5
L15:
  end
L16:
  jump to=L9
L17:
  jump to=L5
L18:
  jump to=L4
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
  jump_if_true to=L17 (constant_integer value=4)
  jump to=L18
EOI
