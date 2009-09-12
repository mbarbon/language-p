#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a + 2;
print !$a
EOP
# main
L1:
  scope_enter scope=0
  assign context=2 (global name="x", slot=1), (add context=4 (global name="a", slot=1), (constant_integer value=2))
  print context=2 (global name="STDOUT", slot=7), (make_list (not context=8 (global name="a", slot=1)))
  scope_leave scope=0
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = abs $t;
EOP
# main
L1:
  scope_enter scope=0
  assign context=2 (global name="x", slot=1), (abs context=4 (global name="t", slot=1))
  scope_leave scope=0
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = "$a\n";
EOP
# main
L1:
  scope_enter scope=0
  assign context=2 (global name="x", slot=1), (concat_assign context=4 (concat_assign context=4 (fresh_string value=""), (global name="a", slot=1)), (constant_string value="\x0a"))
  scope_leave scope=0
  end
EOI
