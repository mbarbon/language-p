#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_ssa_and_diff( <<'EOP', <<'EOI' );
1;
BEGIN {
    3;
}
2;
EOP
# main
L1:
  scope_enter scope=0
  constant_integer value=1
  constant_integer value=2
  scope_leave scope=0
  end
# BEGIN
L1:
  scope_enter scope=0
  return context=0 (make_list (constant_integer value=3))
  scope_leave scope=0
  end
EOI
