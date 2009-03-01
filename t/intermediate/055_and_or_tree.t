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
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L2
  jump L4
L2:
  set t2, (global name=b, slot=1)
  set t3, (get t2)
  jump L3
L3:
  assign (global name=x, slot=1), (get t3)
  end
L4:
  set t3, (get t1)
  jump L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L4
  jump L2
L2:
  set t2, (global name=b, slot=1)
  set t3, (get t2)
  jump L3
L3:
  assign (global name=x, slot=1), (get t3)
  end
L4:
  set t3, (get t1)
  jump L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L2
  jump L6
L2:
  set t2, (global name=b, slot=1)
  set t3, (get t2)
  jump L3
L3:
  jump_if_true (get t3), L4
  jump L7
L4:
  set t4, (global name=c, slot=1)
  set t5, (get t4)
  jump L5
L5:
  assign (global name=x, slot=1), (get t5)
  end
L6:
  set t3, (get t1)
  jump L3
L7:
  set t5, (get t3)
  jump L5
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L6
  jump L2
L2:
  set t2, (global name=b, slot=1)
  set t3, (get t2)
  jump L3
L3:
  jump_if_true (get t3), L7
  jump L4
L4:
  set t4, (global name=c, slot=1)
  set t5, (get t4)
  jump L5
L5:
  assign (global name=x, slot=1), (get t5)
  end
L6:
  set t3, (get t1)
  jump L3
L7:
  set t5, (get t3)
  jump L5
EOI
