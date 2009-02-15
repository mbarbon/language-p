#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L2
  jump L3
L2:
  set t2, (global name=b, slot=1)
  jump L3
L3:
  set t3, (phi L1, t1, L2, t2)
  assign (global name=x, slot=1), (get t3)
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L3
  jump L2
L3:
  set t2, (phi L1, t1, L2, t3)
  assign (global name=x, slot=1), (get t2)
  end
L2:
  set t3, (global name=b, slot=1)
  jump L3
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L2
  jump L3
L2:
  set t2, (global name=b, slot=1)
  jump L3
L3:
  set t3, (phi L1, t1, L2, t2)
  jump_if_true (get t3), L4
  jump L5
L4:
  set t4, (global name=c, slot=1)
  jump L5
L5:
  set t5, (phi L3, t3, L4, t4)
  assign (global name=x, slot=1), (get t5)
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
L1:
  set t1, (global name=a, slot=1)
  jump_if_true (get t1), L3
  jump L2
L3:
  set t2, (phi L1, t1, L2, t3)
  jump_if_true (get t2), L5
  jump L4
L2:
  set t3, (global name=b, slot=1)
  jump L3
L5:
  set t4, (phi L3, t2, L4, t5)
  assign (global name=x, slot=1), (get t4)
  end
L4:
  set t5, (global name=c, slot=1)
  jump L5
EOI
