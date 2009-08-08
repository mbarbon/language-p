#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b : $c + 3;
EOP
# main
L1:
  jump_if_f_gt to=L3 (global name="a", slot=1), (constant_integer value=2)
  jump to=L4
L2:
  set t3, (phi L3, t1, L4, t2)
  assign (global name="x", slot=1), (get t3)
  end
L3:
  set t1, (global name="b", slot=1)
  jump to=L2
L4:
  set t2, (add (global name="c", slot=1), (constant_integer value=3))
  jump to=L2
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b :
     $c < 3 ? $d : $e;
EOP
# main
L1:
  jump_if_f_gt to=L3 (global name="a", slot=1), (constant_integer value=2)
  jump to=L4
L2:
  set t4, (phi L3, t1, L6, t2, L7, t3)
  assign (global name="x", slot=1), (get t4)
  end
L3:
  set t1, (global name="b", slot=1)
  jump to=L2
L4:
  jump_if_f_lt to=L6 (global name="c", slot=1), (constant_integer value=3)
  jump to=L7
L6:
  set t2, (global name="d", slot=1)
  jump to=L2
L7:
  set t3, (global name="e", slot=1)
  jump to=L2
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $a > 2 ? $b : $c;
EOP
# main
L1:
  set t1, (global name="STDOUT", slot=7)
  jump_if_f_gt to=L3 (global name="a", slot=1), (constant_integer value=2)
  jump to=L4
L2:
  set t4, (phi L3, t2, L4, t3)
  print (get t1), (make_list (get t4))
  end
L3:
  set t2, (global name="b", slot=1)
  jump to=L2
L4:
  set t3, (global name="c", slot=1)
  jump to=L2
EOI
