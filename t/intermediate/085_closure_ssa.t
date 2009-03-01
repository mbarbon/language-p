#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_ssa_and_diff( <<'EOP', <<'EOI' );
sub outer {
    return sub {
        3;
    };
}

$x = outer();
$y = sub {
    4
};
EOP
# main
L1:
  assign (global name=x, slot=1), (call context=4 (make_list), (global name=outer, slot=4))
  assign (global name=y, slot=1), (make_closure (constant_sub anoncode))
  end
# outer
L1:
  return (make_list (make_closure (constant_sub anoncode)))
  end
# anoncode
L1:
  return (make_list (constant_integer 3))
  end
# anoncode
L1:
  return (make_list (constant_integer 4))
  end
EOI
