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
  scope_enter scope=0
  global name="a", slot=1
  constant_integer value=2
  add context=4
  global name="x", slot=1
  swap
  assign
  pop
  scope_leave scope=0
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
print !$a
EOP
# main
L1:
  scope_enter scope=0
  global name="STDOUT", slot=7
  global name="a", slot=1
  not context=8
  make_list count=1
  print context=2
  pop
  scope_leave scope=0
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = "$a\n";
EOP
# main
L1:
  scope_enter scope=0
  fresh_string value=""
  global name="a", slot=1
  concat_assign
  constant_string value="\x0a"
  concat_assign
  global name="x", slot=1
  swap
  assign
  pop
  scope_leave scope=0
  end
EOI
