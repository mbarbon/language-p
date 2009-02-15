#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_ssa_and_diff( <<'EOP', <<'EOI' );
foreach $y ( 1, 2 ) {
  3
}
EOP
# main
L1:
  temporary_set index=0 (iterator (make_list (make_list (constant_integer 1), (constant_integer 2))))
  set t1, (global name=y, slot=5)
  temporary_set index=2 (glob_slot slot=1 (get t1))
  temporary_set index=1 (get t1)
  jump L2
L2:
  set t2, (iterator_next (temporary index=0))
  jump_if_null (get t2), L5
  jump L3
L3:
  glob_slot_set slot=1 (temporary index=1), (get t2)
  constant_integer 3
  jump L2
L5:
  jump L6
L6:
  glob_slot_set slot=1 (temporary index=1), (temporary index=2)
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
foreach my $y ( 1, 2 ) {
  3
}
EOP
# main
L1:
  temporary_set index=0 (iterator (make_list (make_list (constant_integer 1), (constant_integer 2))))
  jump L2
L2:
  set t1, (iterator_next (temporary index=0))
  jump_if_null (get t1), L5
  jump L3
L3:
  lexical_set lexical=scalar(y) (get t1)
  constant_integer 3
  jump L2
L5:
  jump L6
L6:
  end
EOI
