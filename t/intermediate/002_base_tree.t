#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = $a + 2;
print !$a
EOP
L1:
  assign (global name=x, slot=1), (add (global name=a, slot=1), (constant_integer 2))
  print (make_list (global name=STDOUT, slot=7), (not (global name=a, slot=1)))
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
$x = abs $t;
EOP
L1:
  assign (global name=x, slot=1), (abs (global name=t, slot=1))
  end
EOI
