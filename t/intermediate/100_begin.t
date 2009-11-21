#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

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

generate_ssa_and_diff( <<'EOP', <<'EOI' );
use Foo (1, 2);

1;
EOP
# main
L1:
  constant_integer value=1
  jump to=L2
L2:
  end
# BEGIN
L1:
  require_file context=2 (constant_string value="Foo.pm")
  set index=1 (find_method method="import" (constant_string value="Foo"))
  set index=2 (make_list (constant_string value="Foo"), (constant_integer value=1), (constant_integer value=2))
  jump_if_null to=L2 (get index=1)
  jump to=L3
L2:
  jump to=L4
L3:
  call context=2 (get index=2), (get index=1)
  jump to=L4
L4:
  end
EOI
