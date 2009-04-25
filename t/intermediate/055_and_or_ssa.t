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
  set t1, (global name="a", slot=1)
  jump_if_true to=L2 (get t1)
  jump to=L4
L2:
  set t2, (global name="b", slot=1)
  jump to=L3
L3:
  set t3, (phi L2, t2, L4, t1)
  assign (global name="x", slot=1), (get t3)
  end
L4:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  set t1, (global name="a", slot=1)
  jump_if_true to=L4 (get t1)
  jump to=L2
L2:
  set t2, (global name="b", slot=1)
  jump to=L3
L3:
  set t3, (phi L4, t1, L2, t2)
  assign (global name="x", slot=1), (get t3)
  end
L4:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  set t1, (global name="a", slot=1)
  jump_if_true to=L2 (get t1)
  jump to=L6
L2:
  set t2, (global name="b", slot=1)
  jump to=L3
L3:
  set t3, (phi L2, t2, L6, t1)
  jump_if_true to=L4 (get t3)
  jump to=L7
L4:
  set t4, (global name="c", slot=1)
  jump to=L5
L5:
  set t5, (phi L4, t4, L7, t3)
  assign (global name="x", slot=1), (get t5)
  end
L6:
  jump to=L3
L7:
  jump to=L5
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  set t1, (global name="a", slot=1)
  jump_if_true to=L6 (get t1)
  jump to=L2
L2:
  set t2, (global name="b", slot=1)
  jump to=L3
L3:
  set t3, (phi L6, t1, L2, t2)
  jump_if_true to=L7 (get t3)
  jump to=L4
L4:
  set t4, (global name="c", slot=1)
  jump to=L5
L5:
  set t5, (phi L7, t3, L4, t4)
  assign (global name="x", slot=1), (get t5)
  end
L6:
  jump to=L3
L7:
  jump to=L5
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $a || $b;
EOP
# main
L1:
  set t1, (global name="a", slot=1)
  set t2, (global name="STDOUT", slot=7)
  jump_if_true to=L4 (get t1)
  jump to=L2
L2:
  set t3, (global name="b", slot=1)
  jump to=L3
L3:
  set t4, (phi L4, t1, L2, t3)
  print (make_list (get t2), (get t4))
  end
L4:
  jump to=L3
EOI
