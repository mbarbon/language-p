#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a + 2
EOP
L1:
  global name=a, slot=1
  constant_integer 2
  add
  global name=x, slot=1
  swap
  assign
  pop
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
print !$a
EOP
L1:
  global name=STDOUT, slot=7
  global name=a, slot=1
  not
  make_list count=2
  print
  pop
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = "$a\n";
EOP
L1:
  fresh_string ""
  global name=a, slot=1
  concat_assign
  constant_string "\x0a"
  concat_assign
  global name=x, slot=1
  swap
  assign
  pop
  end
EOI
