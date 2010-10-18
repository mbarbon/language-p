#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
exists $foo[1];
EOP
# main
L1:
  constant_integer value=1
  global context=8, name="foo", slot=2
  exists_array context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
exists $foo->{1};
EOP
# main
L1:
  constant_integer value=1
  global context=4, name="foo", slot=1
  vivify_hash context=4
  exists_hash context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
exists &foo;
EOP
# main
L1:
  global context=4, name="foo", slot=4
  exists context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
caller;
caller 1;
EOP
# main
L1:
  caller arg_count=0, context=2
  pop
  constant_integer value=1
  caller arg_count=1, context=2
  pop
  jump to=L2
L2:
  end
EOI
