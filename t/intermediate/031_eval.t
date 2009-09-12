#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
eval "1";
package x;
eval "1";
EOP
# main
L1:
  scope_enter scope=0
  constant_string value="1"
  eval warnings=undef, hints=0, globals={}, context=2, lexicals={}, package="main"
  pop
  jump to=L2
L2:
  constant_string value="1"
  eval warnings=undef, hints=0, globals={}, context=2, lexicals={}, package="x"
  pop
  scope_leave scope=0
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = eval { 1 };
eval { 1 };
EOP
# main
L1:
  scope_enter scope=0
  scope_enter scope=1
  constant_integer value=1
  scope_leave scope=1
  global name="x", slot=1
  swap
  assign context=2
  pop
  scope_enter scope=2
  constant_integer value=1
  pop
  scope_leave scope=2
  scope_leave scope=0
  end
EOI
