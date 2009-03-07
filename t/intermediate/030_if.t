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
  constant_integer 0
  pop
  jump to=L3
L2:
  end
L3:
  global name=a, slot=1
  constant_integer 2
  jump_if_f_lt false=L4, true=L5
L4:
  constant_integer 1
  pop
  jump to=L2
L5:
  jump to=L2
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
  constant_integer 0
  pop
  jump to=L6
L2:
  constant_integer 4
  pop
  end
L3:
  constant_integer 3
  pop
  jump to=L2
L4:
  global name=a, slot=1
  constant_integer 12
  jump_if_f_lt false=L3, true=L5
L5:
  constant_integer 2
  pop
  jump to=L2
L6:
  global name=a, slot=1
  constant_integer 11
  jump_if_f_lt false=L4, true=L7
L7:
  constant_integer 1
  pop
  jump to=L2
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
  constant_integer 0
  pop
  jump to=L3
L2:
  constant_integer 2
  pop
  end
L3:
  global name=a, slot=1
  constant_integer 1
  subtract
  jump_if_true false=L5, true=L4
L4:
  constant_integer 1
  pop
  jump to=L2
L5:
  jump to=L2
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
  constant_integer 0
  pop
  jump to=L3
L2:
  constant_integer 2
  pop
  end
L3:
  global name=a, slot=1
  jump_if_true false=L7, true=L5
L4:
  constant_integer 1
  pop
  jump to=L2
L5:
  global name=b, slot=1
  jump_if_true false=L6, true=L4
L6:
  jump to=L2
L7:
  jump to=L2
EOI

generate_and_diff( <<'EOP', <<'EOI' );
if( $y eq '' ) {
    3 unless $z;
}
EOP
# main
L1:
  jump to=L3
L2:
  end
L3:
  global name=y, slot=1
  constant_string ""
  jump_if_s_eq false=L9, true=L6
L6:
  global name=z, slot=1
  jump_if_true false=L7, true=L8
L7:
  constant_integer 3
  pop
  jump to=L2
L8:
  jump to=L2
L9:
  jump to=L2
EOI
