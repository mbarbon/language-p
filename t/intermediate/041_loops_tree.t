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
L1:
  assign (global name=i, slot=1), (constant_integer 0)
  jump L2
L2:
  jump_if_f_lt (global name=i, slot=1), (constant_integer 10), L3
  jump L5
L3:
  print (make_list (global name=STDOUT, slot=7), (global name=i, slot=1))
  jump L4
L5:
  end
L4:
  assign (global name=i, slot=1), (add (global name=i, slot=1), (constant_integer 1))
  jump L2
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
foreach $i ( 1, 2 ) {
  print $i;
}
EOP
L1:
  temporary_set index=0 (iterator (make_list (make_list (constant_integer 1), (constant_integer 2))))
  set t1, (global name=i, slot=5)
  temporary_set index=2 (glob_slot slot=1 (get t1))
  temporary_set index=1 (get t1)
  jump L2
L2:
  set t2, (iterator_next (temporary index=0))
  jump_if_null (get t2), L5
  jump L3
L5:
  jump L6
L3:
  glob_slot_set slot=1 (temporary index=1), (get t2)
  print (make_list (global name=STDOUT, slot=7), (global name=i, slot=1))
  jump L2
L6:
  glob_slot_set slot=1 (temporary index=1), (temporary index=2)
  end
EOI
