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
  set index=3 (phi L3, 1, L4, 2)
  assign context=2 (global name="x", slot=1), (get index=3)
  jump to=L5
L3:
  set index=1 (global name="b", slot=1)
  jump to=L2
L4:
  set index=2 (add context=4 (global name="c", slot=1), (constant_integer value=3))
  jump to=L2
L5:
  end
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
  set index=4 (phi L3, 1, L6, 2, L7, 3)
  assign context=2 (global name="x", slot=1), (get index=4)
  jump to=L8
L3:
  set index=1 (global name="b", slot=1)
  jump to=L2
L4:
  jump_if_f_lt to=L6 (global name="c", slot=1), (constant_integer value=3)
  jump to=L7
L6:
  set index=2 (global name="d", slot=1)
  jump to=L2
L7:
  set index=3 (global name="e", slot=1)
  jump to=L2
L8:
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
print $a > 2 ? $b : $c;
EOP
# main
L1:
  set index=1 (global name="STDOUT", slot=7)
  jump_if_f_gt to=L3 (global name="a", slot=1), (constant_integer value=2)
  jump to=L4
L2:
  set index=4 (phi L3, 2, L4, 3)
  print context=2 (get index=1), (make_array (get index=4))
  jump to=L5
L3:
  set index=2 (global name="b", slot=1)
  jump to=L2
L4:
  set index=3 (global name="c", slot=1)
  jump to=L2
L5:
  end
EOI
