#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1:
  set t1, (global name="a", slot=1)
  jump_if_true to=L2 (get t1)
  jump to=L4
L2:
  set t2, (global name="b", slot=1)
  set t3, (get t2)
  jump to=L3
L3:
  assign (global name="x", slot=1), (get t3)
  end
L4:
  set t3, (get t1)
  jump to=L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  set t1, (global name="a", slot=1)
  jump_if_true to=L4 (get t1)
  jump to=L2
L2:
  set t2, (global name="b", slot=1)
  set t3, (get t2)
  jump to=L3
L3:
  assign (global name="x", slot=1), (get t3)
  end
L4:
  set t3, (get t1)
  jump to=L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  set t1, (global name="a", slot=1)
  jump_if_true to=L2 (get t1)
  jump to=L6
L2:
  set t2, (global name="b", slot=1)
  set t3, (get t2)
  jump to=L3
L3:
  jump_if_true to=L4 (get t3)
  jump to=L7
L4:
  set t4, (global name="c", slot=1)
  set t5, (get t4)
  jump to=L5
L5:
  assign (global name="x", slot=1), (get t5)
  end
L6:
  set t3, (get t1)
  jump to=L3
L7:
  set t5, (get t3)
  jump to=L5
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  set t1, (global name="a", slot=1)
  jump_if_true to=L6 (get t1)
  jump to=L2
L2:
  set t2, (global name="b", slot=1)
  set t3, (get t2)
  jump to=L3
L3:
  jump_if_true to=L7 (get t3)
  jump to=L4
L4:
  set t4, (global name="c", slot=1)
  set t5, (get t4)
  jump to=L5
L5:
  assign (global name="x", slot=1), (get t5)
  end
L6:
  set t3, (get t1)
  jump to=L3
L7:
  set t5, (get t3)
  jump to=L5
EOI
