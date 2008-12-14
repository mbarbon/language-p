#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
$x = $a + 2
EOP
L1:
  global name=x, slot=1
  global name=a, slot=1
  constant_integer 2
  add
  assign
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
EOI
