#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_tree_and_diff( <<'EOP', <<'EOI' );
for( $i = 0; $i < 10; $i = $i + 1 ) {
  print $i;
}
EOP
# main
L1:
  assign context=2 (global context=20, name="i", slot=1), (constant_integer value=0)
  jump to=L2
L2:
  jump_if_f_lt to=L3 (global context=4, name="i", slot=1), (constant_integer value=10)
  jump to=L5
L3:
  print context=2 (global context=4, name="STDOUT", slot=7), (make_array context=8 (global context=4, name="i", slot=1))
  jump to=L4
L4:
  assign context=2 (global context=20, name="i", slot=1), (add context=4 (global context=4, name="i", slot=1), (constant_integer value=1))
  jump to=L2
L5:
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
foreach $i ( 1, 2 ) {
  print $i;
}
EOP
# main
L1:
  temporary_set index=0, slot=9 (iterator (make_list context=8 (make_list context=8 (constant_integer value=1), (constant_integer value=2))))
  temporary_set index=1, slot=5 (global context=4, name="i", slot=5)
  localize_glob_slot index=2, name="i", slot=1
  jump to=L2
L2:
  set index=1 (iterator_next (temporary index=0, slot=9))
  jump_if_null to=L5 (get index=1)
  jump to=L3
L3:
  glob_slot_set slot=1 (temporary index=1, slot=5), (get index=1)
  jump to=L7
L5:
  jump to=L6
L6:
  temporary_clear index=1, slot=5
  restore_glob_slot index=2, name="i", slot=1
  jump to=L8
L7:
  print context=2 (global context=4, name="STDOUT", slot=7), (make_array context=8 (global context=4, name="i", slot=1))
  jump to=L2
L8:
  end
EOI
