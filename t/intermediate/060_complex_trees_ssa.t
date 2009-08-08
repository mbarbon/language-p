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
  set t1, (global name="STDOUT", slot=7)
  jump_if_true to=L5 (defined context=4 (want context=4))
  jump to=L6
L2:
  set t4, (phi L3, t2, L4, t3)
  print (get t1), (make_list (get t4))
  return (make_list)
  end
L3:
  set t2, (constant_string value="ok\x0a")
  jump to=L2
L4:
  set t3, (constant_string value="not ok\x0a")
  jump to=L2
L5:
  jump_if_true to=L3 (not (want context=4))
  jump to=L7
L6:
  jump to=L4
L7:
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
  jump to=L6
L11:
  jump to=L4
L12:
  constant_integer value=7
  jump to=L3
L13:
  jump to=L9
L14:
  jump to=L6
L15:
  jump to=L4
L3:
  constant_integer value=5
  jump to=L4
L4:
  constant_integer value=6
  end
L6:
  jump_if_true to=L7 (constant_integer value=3)
  jump to=L13
L7:
  constant_integer value=2
  jump to=L9
L9:
  jump_if_true to=L14 (constant_integer value=4)
  jump to=L15
EOI
