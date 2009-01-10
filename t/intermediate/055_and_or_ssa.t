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
  set t5, (global name=b, slot=1)
  jump L3
L3:
  set t6, (phi L1, t1, L2, t5)
  assign (global name=x, slot=1), (get t6)
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
  set t5, (phi L1, t1, L2, t6)
  assign (global name=x, slot=1), (get t5)
  end
L2:
  set t6, (global name=b, slot=1)
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
  set t5, (global name=b, slot=1)
  jump L3
L3:
  set t6, (phi L1, t1, L2, t5)
  jump_if_true (get t6), L4
  jump L5
L4:
  set t10, (global name=c, slot=1)
  jump L5
L5:
  set t11, (phi L3, t6, L4, t10)
  assign (global name=x, slot=1), (get t11)
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
  set t5, (phi L1, t1, L2, t9)
  jump_if_true (get t5), L5
  jump L4
L2:
  set t9, (global name=b, slot=1)
  jump L3
L5:
  set t10, (phi L3, t5, L4, t11)
  assign (global name=x, slot=1), (get t10)
  end
L4:
  set t11, (global name=c, slot=1)
  jump L5
EOI
