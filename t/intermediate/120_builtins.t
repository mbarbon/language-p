#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
exists $foo[1];
EOP
# main
L1:
  scope_enter scope=0
  constant_integer value=1
  global name="foo", slot=2
  exists_array
  pop
  scope_leave scope=0
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
exists $foo->{1};
EOP
# main
L1:
  scope_enter scope=0
  constant_integer value=1
  global name="foo", slot=1
  vivify_hash
  exists_hash
  pop
  scope_leave scope=0
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
exists &foo;
EOP
# main
L1:
  scope_enter scope=0
  global name="foo", slot=4
  exists context=2
  pop
  scope_leave scope=0
  end
EOI
