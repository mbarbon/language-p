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
  set t1, (global name=STDOUT, slot=7)
  jump_if_true (defined context=4 (want context=4)), L5
  jump L6
L2:
  set t4, (phi L3, t2, L4, t3)
  print (make_list (get t1), (get t4))
  return (make_list)
  end
L3:
  set t2, (constant_string "ok\x0a")
  jump L2
L4:
  set t3, (constant_string "not ok\x0a")
  jump L2
L5:
  jump_if_true (not (want context=4)), L3
  jump L7
L6:
  jump L4
L7:
  jump L4
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
  constant_integer 1
  jump L6
L11:
  jump L4
L12:
  constant_integer 7
  jump L3
L13:
  jump L9
L14:
  jump L6
L15:
  jump L4
L3:
  constant_integer 5
  jump L4
L4:
  constant_integer 6
  end
L6:
  jump_if_true (constant_integer 3), L7
  jump L13
L7:
  constant_integer 2
  jump L9
L9:
  jump_if_true (constant_integer 4), L14
  jump L15
EOI
