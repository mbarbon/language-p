#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
0;
unless( $a < 2 ) {
    1;
}
EOP
L1:
  constant_integer 0
  pop
  jump to=L3
L3:
  global name=a, slot=1
  constant_integer 2
  jump_if_f_lt false=L4, true=L2
L4:
  constant_integer 1
  pop
  jump to=L2
L2:
  end
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
L1:
  constant_integer 0
  pop
  jump to=L6
L6:
  global name=a, slot=1
  constant_integer 11
  jump_if_f_lt false=L4, true=L7
L7:
  constant_integer 1
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
L3:
  constant_integer 3
  pop
  jump to=L2
L2:
  constant_integer 4
  pop
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
0;
if( $a - 1 ) {
    1
}
2;
EOP
L1:
  constant_integer 0
  pop
  jump to=L3
L3:
  global name=a, slot=1
  constant_integer 1
  subtract
  jump_if_true false=L2, true=L4
L4:
  constant_integer 1
  pop
  jump to=L2
L2:
  constant_integer 2
  pop
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
0;
if( $a && $b ) {
    1
}
2;
EOP
L1:
  constant_integer 0
  pop
  jump to=L3
L5:
  global name=b, slot=1
  jump_if_true false=L2, true=L4
L3:
  global name=a, slot=1
  jump_if_true false=L2, true=L5
L4:
  constant_integer 1
  pop
  jump to=L2
L2:
  constant_integer 2
  pop
  end
EOI
