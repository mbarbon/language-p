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
  set t3, (get t1)
  jump L3
L2:
  set t2, (global name=b, slot=1)
  set t3, (get t2)
  jump L3
L3:
  assign (global name=x, slot=1), (get t3)
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  set t2, (get t1)
  jump_if_true (get t1), L3
  jump L2
L3:
  assign (global name=x, slot=1), (get t2)
  end
L2:
  set t3, (global name=b, slot=1)
  set t2, (get t3)
  jump L3
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L2
  set t3, (get t1)
  jump L3
L2:
  set t2, (global name=b, slot=1)
  set t3, (get t2)
  jump L3
L3:
  jump_if_true (get t3), L4
  set t5, (get t3)
  jump L5
L4:
  set t4, (global name=c, slot=1)
  set t5, (get t4)
  jump L5
L5:
  assign (global name=x, slot=1), (get t5)
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  set t1, (global name=a, slot=1)
  set t2, (get t1)
  jump_if_true (get t1), L3
  jump L2
L3:
  set t4, (get t2)
  jump_if_true (get t2), L5
  jump L4
L2:
  set t3, (global name=b, slot=1)
  set t2, (get t3)
  jump L3
L5:
  assign (global name=x, slot=1), (get t4)
  end
L4:
  set t5, (global name=c, slot=1)
  set t4, (get t5)
  jump L5
EOI
