#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
0;
unless( $a < 2 ) {
    1;
}
EOP
# main
L1:
  scope_enter scope=0
  constant_integer value=0
  pop
  scope_enter scope=1
  jump to=L2
L2:
  global name="a", slot=1
  constant_integer value=2
  jump_if_f_lt false=L4, true=L6
L3:
  scope_leave scope=1
  scope_leave scope=0
  end
L4:
  scope_enter scope=2
  constant_integer value=1
  pop
  scope_leave scope=2
  jump to=L3
L6:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
0;
if( $a < 11 ) {
    1
} elsif( $a < 12 ) {
    2
} else {
    3
}
4;
EOP
# main
L1:
  scope_enter scope=0
  constant_integer value=0
  pop
  scope_enter scope=1
  jump to=L2
L2:
  global name="a", slot=1
  constant_integer value=11
  jump_if_f_lt false=L5, true=L4
L3:
  scope_leave scope=1
  constant_integer value=4
  pop
  scope_leave scope=0
  end
L4:
  scope_enter scope=2
  constant_integer value=1
  pop
  scope_leave scope=2
  jump to=L3
L5:
  global name="a", slot=1
  constant_integer value=12
  jump_if_f_lt false=L7, true=L6
L6:
  scope_enter scope=3
  constant_integer value=2
  pop
  scope_leave scope=3
  jump to=L3
L7:
  scope_enter scope=4
  constant_integer value=3
  pop
  scope_leave scope=4
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
0;
if( $a - 1 ) {
    1
}
2;
EOP
# main
L1:
  scope_enter scope=0
  constant_integer value=0
  pop
  scope_enter scope=1
  jump to=L2
L2:
  global name="a", slot=1
  constant_integer value=1
  subtract
  jump_if_true false=L6, true=L4
L3:
  scope_leave scope=1
  constant_integer value=2
  pop
  scope_leave scope=0
  end
L4:
  scope_enter scope=2
  constant_integer value=1
  pop
  scope_leave scope=2
  jump to=L3
L6:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
0;
if( $a && $b ) {
    1
}
2;
EOP
# main
L1:
  scope_enter scope=0
  constant_integer value=0
  pop
  scope_enter scope=1
  jump to=L2
L2:
  global name="a", slot=1
  jump_if_true false=L7, true=L6
L3:
  scope_leave scope=1
  constant_integer value=2
  pop
  scope_leave scope=0
  end
L4:
  scope_enter scope=2
  constant_integer value=1
  pop
  scope_leave scope=2
  jump to=L3
L6:
  global name="b", slot=1
  jump_if_true false=L8, true=L4
L7:
  jump to=L3
L8:
  jump to=L3
EOI

generate_and_diff( <<'EOP', <<'EOI' );
if( $y eq '' ) {
    3 unless $z;
}
EOP
# main
L1:
  scope_enter scope=0
  scope_enter scope=1
  jump to=L2
L10:
  jump to=L3
L11:
  jump to=L7
L2:
  global name="y", slot=1
  constant_string value=""
  jump_if_s_eq false=L10, true=L4
L3:
  scope_leave scope=1
  scope_leave scope=0
  end
L4:
  scope_enter scope=2
  jump to=L6
L6:
  global name="z", slot=1
  jump_if_true false=L8, true=L11
L7:
  scope_leave scope=2
  jump to=L3
L8:
  constant_integer value=3
  pop
  jump to=L7
EOI
