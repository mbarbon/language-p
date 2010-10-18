#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_tree_and_diff( <<'EOP', <<'EOI' );
2 and last while 1
EOP
# main
L1:
  jump to=L2
L10:
  jump to=L5
L2:
  jump_if_true to=L3 (constant_integer value=1)
  jump to=L10
L3:
  set index=1 (constant_integer value=2)
  jump_if_true to=L6 (get index=1)
  jump to=L8
L5:
  end
L6:
  jump to=L5
L8:
  jump to=L2
EOI
