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
  constant_integer 1
  constant_integer 2
  end
# BEGIN
L1:
  return (make_list (constant_integer 3))
  end
EOI
