#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
sub foo {
    print "ok $_[0]\n";
}

foo( 1 );
EOP
L1:
  constant_integer 1
  make_list count=1
  global name=foo, slot=4
  call context=2
  pop
  end
EOI
