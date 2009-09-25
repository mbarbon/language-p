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
  constant_integer value=0
  pop
  jump to=L3
L3:
  global name="a", slot=1
  constant_integer value=2
  jump_if_f_lt false=L5, true=L7
L4:
  end
L5:
  constant_integer value=1
  pop
  jump to=L4
L7:
  jump to=L4
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
  constant_integer value=0
  pop
  jump to=L3
L3:
  global name="a", slot=1
  constant_integer value=11
  jump_if_f_lt false=L6, true=L5
L4:
  constant_integer value=4
  pop
  jump to=L9
L5:
  constant_integer value=1
  pop
  jump to=L4
L6:
  global name="a", slot=1
  constant_integer value=12
  jump_if_f_lt false=L8, true=L7
L7:
  constant_integer value=2
  pop
  jump to=L4
L8:
  constant_integer value=3
  pop
  jump to=L4
L9:
  end
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
  constant_integer value=0
  pop
  jump to=L3
L3:
  global name="a", slot=1
  constant_integer value=1
  subtract context=4
  jump_if_true false=L8, true=L5
L4:
  constant_integer value=2
  pop
  jump to=L7
L5:
  constant_integer value=1
  pop
  jump to=L4
L7:
  end
L8:
  jump to=L4
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
  constant_integer value=0
  pop
  jump to=L3
L10:
  jump to=L4
L3:
  global name="a", slot=1
  jump_if_true false=L9, true=L7
L4:
  constant_integer value=2
  pop
  jump to=L8
L5:
  constant_integer value=1
  pop
  jump to=L4
L7:
  global name="b", slot=1
  jump_if_true false=L10, true=L5
L8:
  end
L9:
  jump to=L4
EOI

generate_and_diff( <<'EOP', <<'EOI' );
if( $y eq '' ) {
    3 unless $z;
}
EOP
# main
L1:
  jump to=L2
L10:
  jump to=L3
L11:
  jump to=L3
L2:
  global name="y", slot=1
  constant_string value=""
  jump_if_s_eq false=L10, true=L6
L3:
  end
L6:
  global name="z", slot=1
  jump_if_true false=L8, true=L11
L8:
  constant_integer value=3
  pop
  jump to=L3
EOI
