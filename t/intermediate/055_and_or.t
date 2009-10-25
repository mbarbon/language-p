#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b;
EOP
# main
L1:
  global name="a", slot=1
  dup
  jump_if_true false=L5, true=L2
L2:
  pop
  global name="b", slot=1
  jump to=L3
L3:
  global name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L4
L4:
  end
L5:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b;
EOP
# main
L1:
  global name="a", slot=1
  dup
  jump_if_true false=L2, true=L5
L2:
  pop
  global name="b", slot=1
  jump to=L3
L3:
  global name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L4
L4:
  end
L5:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a && $b && $c;
EOP
# main
L1:
  global name="a", slot=1
  dup
  jump_if_true false=L7, true=L2
L2:
  pop
  global name="b", slot=1
  jump to=L3
L3:
  dup
  jump_if_true false=L8, true=L4
L4:
  pop
  global name="c", slot=1
  jump to=L5
L5:
  global name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L6
L6:
  end
L7:
  jump to=L3
L8:
  jump to=L5
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a || $b || $c;
EOP
# main
L1:
  global name="a", slot=1
  dup
  jump_if_true false=L2, true=L7
L2:
  pop
  global name="b", slot=1
  jump to=L3
L3:
  dup
  jump_if_true false=L4, true=L8
L4:
  pop
  global name="c", slot=1
  jump to=L5
L5:
  global name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L6
L6:
  end
L7:
  jump to=L3
L8:
  jump to=L5
EOI
