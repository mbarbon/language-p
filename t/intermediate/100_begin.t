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
  constant_integer value=1
  constant_integer value=2
  jump to=L2
L2:
  end
# BEGIN
L1:
  lexical_state_set index=1
  return context=1 (make_list (constant_integer value=3))
  jump to=L2
L2:
  end
EOI
