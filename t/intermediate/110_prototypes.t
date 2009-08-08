#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
push @foo, 1, 2;
EOP
# main
L1:
  global name="foo", slot=2
  constant_integer value=1
  constant_integer value=2
  make_list count=2
  array_push
  pop
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
pop @foo;
EOP
# main
L1:
  global name="foo", slot=2
  array_pop context=2
  pop
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
sub mypush(\@@);

mypush @foo, 1, 2;
EOP
# main
L1:
  global name="foo", slot=2
  reference
  constant_integer value=1
  constant_integer value=2
  make_list count=3
  global name="mypush", slot=4
  call context=2
  pop
  end
EOI
