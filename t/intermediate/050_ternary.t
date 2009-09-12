#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b : $c + 3;
EOP
# main
L1:
  scope_enter scope=0
  global name="a", slot=1
  constant_integer value=2
  jump_if_f_gt false=L4, true=L3
L2:
  global name="x", slot=1
  swap
  assign context=2
  pop
  scope_leave scope=0
  end
L3:
  global name="b", slot=1
  jump to=L2
L4:
  global name="c", slot=1
  constant_integer value=3
  add context=4
  jump to=L2
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a > 2 ? $b :
     $c < 3 ? $d : $e;
EOP
# main
L1:
  scope_enter scope=0
  global name="a", slot=1
  constant_integer value=2
  jump_if_f_gt false=L4, true=L3
L2:
  global name="x", slot=1
  swap
  assign context=2
  pop
  scope_leave scope=0
  end
L3:
  global name="b", slot=1
  jump to=L2
L4:
  global name="c", slot=1
  constant_integer value=3
  jump_if_f_lt false=L7, true=L6
L6:
  global name="d", slot=1
  jump to=L2
L7:
  global name="e", slot=1
  jump to=L2
EOI
