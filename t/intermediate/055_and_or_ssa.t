#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1:
  set index=1 (global name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L5
L2:
  set index=2 (global name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L2, 2, L5, 1)
  assign context=2 (global name="x", slot=1), (get index=3)
  jump to=L4
L4:
  end
L5:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$a &&= $b;
EOP
# main
L1:
  set index=1 (global name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L5
L2:
  set index=2 (assign (get index=1), (global name="b", slot=1))
  jump to=L3
L3:
  jump to=L4
L4:
  end
L5:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  set index=1 (global name="a", slot=1)
  jump_if_true to=L5 (get index=1)
  jump to=L2
L2:
  set index=2 (global name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L5, 1, L2, 2)
  assign context=2 (global name="x", slot=1), (get index=3)
  jump to=L4
L4:
  end
L5:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$a ||= $b;
EOP
# main
L1:
  set index=1 (global name="a", slot=1)
  jump_if_true to=L5 (get index=1)
  jump to=L2
L2:
  set index=2 (assign (get index=1), (global name="b", slot=1))
  jump to=L3
L3:
  jump to=L4
L4:
  end
L5:
  jump to=L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  set index=1 (global name="a", slot=1)
  jump_if_true to=L2 (get index=1)
  jump to=L7
L2:
  set index=2 (global name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L2, 2, L7, 1)
  jump_if_true to=L4 (get index=3)
  jump to=L8
L4:
  set index=4 (global name="c", slot=1)
  jump to=L5
L5:
  set index=5 (phi L4, 4, L8, 3)
  assign context=2 (global name="x", slot=1), (get index=5)
  jump to=L6
L6:
  end
L7:
  jump to=L3
L8:
  jump to=L5
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  set index=1 (global name="a", slot=1)
  jump_if_true to=L7 (get index=1)
  jump to=L2
L2:
  set index=2 (global name="b", slot=1)
  jump to=L3
L3:
  set index=3 (phi L7, 1, L2, 2)
  jump_if_true to=L8 (get index=3)
  jump to=L4
L4:
  set index=4 (global name="c", slot=1)
  jump to=L5
L5:
  set index=5 (phi L8, 3, L4, 4)
  assign context=2 (global name="x", slot=1), (get index=5)
  jump to=L6
L6:
  end
L7:
  jump to=L3
L8:
  jump to=L5
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $a || $b;
EOP
# main
L1:
  set index=1 (global name="a", slot=1)
  set index=2 (global name="STDOUT", slot=7)
  jump_if_true to=L5 (get index=1)
  jump to=L2
L2:
  set index=3 (global name="b", slot=1)
  jump to=L3
L3:
  set index=4 (phi L5, 1, L2, 3)
  print context=2 (get index=2), (make_list (get index=4))
  jump to=L4
L4:
  end
L5:
  jump to=L3
EOI
