#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L2
  jump L4
L2:
  set t2, (global name=b, slot=1)
  jump L3
L3:
  set t3, (phi L2, t2, L4, t1)
  assign (global name=x, slot=1), (get t3)
  end
L4:
  jump L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L4
  jump L2
L2:
  set t2, (global name=b, slot=1)
  jump L3
L3:
  set t3, (phi L4, t1, L2, t2)
  assign (global name=x, slot=1), (get t3)
  end
L4:
  jump L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L2
  jump L6
L2:
  set t2, (global name=b, slot=1)
  jump L3
L3:
  set t3, (phi L2, t2, L6, t1)
  jump_if_true (get t3), L4
  jump L7
L4:
  set t4, (global name=c, slot=1)
  jump L5
L5:
  set t5, (phi L4, t4, L7, t3)
  assign (global name=x, slot=1), (get t5)
  end
L6:
  jump L3
L7:
  jump L5
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L6
  jump L2
L2:
  set t2, (global name=b, slot=1)
  jump L3
L3:
  set t3, (phi L6, t1, L2, t2)
  jump_if_true (get t3), L7
  jump L4
L4:
  set t4, (global name=c, slot=1)
  jump L5
L5:
  set t5, (phi L7, t3, L4, t4)
  assign (global name=x, slot=1), (get t5)
  end
L6:
  jump L3
L7:
  jump L5
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $a || $b;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  set t2, (global name=STDOUT, slot=7)
  jump_if_true (get t1), L4
  jump L2
L2:
  set t3, (global name=b, slot=1)
  jump L3
L3:
  set t4, (phi L4, t1, L2, t3)
  print (get t2), (make_list (get t4))
  end
L4:
  jump L3
EOI
