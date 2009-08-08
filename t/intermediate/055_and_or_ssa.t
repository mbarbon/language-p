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
  set index=1 (global name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L4
L2:
  set index=2 (global name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L2, 2, L4, 1)
  assign (global name="x", slot=1), (get index=3)
  end
L4:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  set index=1 (global name="a", slot=1)
  jump_if_true to=L4 (get index=1)
  jump to=L2
L2:
  set index=2 (global name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L4, 1, L2, 2)
  assign (global name="x", slot=1), (get index=3)
  end
L4:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  set index=1 (global name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L6
L2:
  set index=2 (global name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L2, 2, L6, 1)
  jump_if_true to=L4 (get index=3)
  jump to=L7
L4:
  set index=4 (global name="c", slot=1)
  jump to=L5
L5:
  set index=5 (phi L4, 4, L7, 3)
  assign (global name="x", slot=1), (get index=5)
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
  set index=1 (global name="a", slot=1)
  jump_if_true to=L6 (get index=1)
  jump to=L2
L2:
  set index=2 (global name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L6, 1, L2, 2)
  jump_if_true to=L7 (get index=3)
  jump to=L4
L4:
  set index=4 (global name="c", slot=1)
  jump to=L5
L5:
  set index=5 (phi L7, 3, L4, 4)
  assign (global name="x", slot=1), (get index=5)
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
  set index=1 (global name="a", slot=1)
  set index=2 (global name="STDOUT", slot=7)
  jump_if_true to=L4 (get index=1)
  jump to=L2
L2:
  set index=3 (global name="b", slot=1)
  jump to=L3
L3:
  set index=4 (phi L4, 1, L2, 3)
  print (get index=2), (make_list (get index=4))
  end
L4:
  jump to=L3
EOI
