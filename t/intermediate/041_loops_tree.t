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
  assign (global name="i", slot=1), (constant_integer value=0)
  jump to=L2
L2:
  jump_if_f_lt to=L3 (global name="i", slot=1), (constant_integer value=10)
  jump to=L5
L3:
  print (make_list (global name="STDOUT", slot=7), (global name="i", slot=1))
  jump to=L4
L4:
  assign (global name="i", slot=1), (add (global name="i", slot=1), (constant_integer value=1))
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
  temporary_set index=0 (iterator (make_list (make_list (constant_integer value=1), (constant_integer value=2))))
  set index=1 (global name="i", slot=5)
  temporary_set index=2 (glob_slot slot=1 (get index=1))
  temporary_set index=1 (get index=1)
  jump to=L2
L2:
  set index=2 (iterator_next (temporary index=0))
  jump_if_null to=L5 (get index=2)
  jump to=L3
L3:
  glob_slot_set slot=1 (temporary index=1), (get index=2)
  print (make_list (global name="STDOUT", slot=7), (global name="i", slot=1))
  jump to=L2
L5:
  jump to=L6
L6:
  glob_slot_set slot=1 (temporary index=1), (temporary index=2)
  end
EOI
