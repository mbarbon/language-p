#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

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
  eval warnings=undef, hints=0, globals={}, context=2, lexicals={}, package=main
  pop
  constant_string value="1"
  eval warnings=undef, hints=0, globals={}, context=2, lexicals={}, package=x
  pop
  scope_leave scope=0
  end
EOI
