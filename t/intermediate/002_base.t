#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a + 2
EOP
# main
L1:
  global name="a", slot=1
  constant_integer value=2
  add context=4
  global name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
print !$a
EOP
# main
L1:
  global name="STDOUT", slot=7
  global name="a", slot=1
  not context=8
  make_array context=8, count=1
  print context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = "$a\n";
EOP
# main
L1:
  fresh_string value=""
  global name="a", slot=1
  concat_assign context=4
  constant_string value="\x0a"
  concat_assign context=4
  global name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L2
L2:
  end
EOI
