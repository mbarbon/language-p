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
  jump_if_f_gt (global name=a, slot=1), (constant_integer 2), L3
  jump L4
L3:
  set t1, (global name=b, slot=1)
  jump L2
L4:
  set t2, (add (global name=c, slot=1), (constant_integer 3))
  jump L2
L2:
  set t3, (phi L3, t1, L4, t2)
  assign (global name=x, slot=1), (get t3)
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b :
     $c < 3 ? $d : $e;
EOP
# main
L1:
  jump_if_f_gt (global name=a, slot=1), (constant_integer 2), L3
  jump L4
L3:
  set t1, (global name=b, slot=1)
  jump L2
L4:
  jump_if_f_lt (global name=c, slot=1), (constant_integer 3), L6
  jump L7
L2:
  set t2, (phi L3, t1, L6, t3, L7, t4)
  assign (global name=x, slot=1), (get t2)
  end
L6:
  set t3, (global name=d, slot=1)
  jump L2
L7:
  set t4, (global name=e, slot=1)
  jump L2
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $a > 2 ? $b : $c;
EOP
# main
L1:
  set t1, (global name=STDOUT, slot=7)
  jump_if_f_gt (global name=a, slot=1), (constant_integer 2), L3
  jump L4
L3:
  set t2, (global name=b, slot=1)
  jump L2
L4:
  set t3, (global name=c, slot=1)
  jump L2
L2:
  set t4, (phi L3, t2, L4, t3)
  print (make_list (get t1), (get t4))
  end
EOI
