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
  assign (global name="x", slot=1), (add (global name="a", slot=1), (constant_integer value=2))
  print (make_list (global name="STDOUT", slot=7), (not (global name="a", slot=1)))
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = abs $t;
EOP
# main
L1:
  assign (global name="x", slot=1), (abs context=4 (global name="t", slot=1))
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = "$a\n";
EOP
# main
L1:
  assign (global name="x", slot=1), (concat_assign (concat_assign (fresh_string value=""), (global name="a", slot=1)), (constant_string value="\x0a"))
  end
EOI
