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
  temporary_set index=0, slot=9 (iterator (make_list (make_list (constant_integer value=1), (constant_integer value=2))))
  set index=1 (global name="y", slot=5)
  temporary_set index=2, slot=1 (glob_slot slot=1 (get index=1))
  temporary_set index=1, slot=5 (get index=1)
  jump to=L2
L2:
  set index=2 (iterator_next (temporary index=0, slot=9))
  jump_if_null to=L5 (get index=2)
  jump to=L3
L3:
  glob_slot_set slot=1 (temporary index=1, slot=5), (get index=2)
  jump to=L7
L5:
  jump to=L6
L6:
  glob_slot_set slot=1 (temporary index=1, slot=5), (temporary index=2, slot=1)
  jump to=L8
L7:
  constant_integer value=3
  jump to=L2
L8:
  end
EOI

generate_ssa_and_diff( <<'EOP', <<'EOI' );
foreach my $y ( 1, 2 ) {
  3
}
EOP
# main
L1:
  temporary_set index=0, slot=9 (iterator (make_list (make_list (constant_integer value=1), (constant_integer value=2))))
  jump to=L2
L2:
  set index=1 (iterator_next (temporary index=0, slot=9))
  jump_if_null to=L5 (get index=1)
  jump to=L3
L3:
  lexical_set index=0 (get index=1)
  jump to=L7
L5:
  jump to=L6
L6:
  end
L7:
  constant_integer value=3
  jump to=L2
EOI
