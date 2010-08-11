#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
eval "1";
package x;
eval "1";
EOP
# main
L1:
  constant_string value="1"
  eval context=2, globals={}, hints=0, lexicals={}, package="main", warnings=undef
  pop
  jump to=L2
L2:
  lexical_state_set index=1
  constant_string value="1"
  eval context=2, globals={}, hints=0, lexicals={}, package="x", warnings=undef
  pop
  jump to=L3
L3:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
$x = eval { 1 };
eval {
    package x;
    1
};
EOP
# main
L1:
  global name="@", slot=1
  undef
  constant_integer value=1
  global name="@", slot=1
  undef
  jump to=L2
L2:
  global name="x", slot=1
  swap
  assign context=2
  pop
  jump to=L3
L3:
  lexical_state_save index=0
  global name="@", slot=1
  undef
  jump to=L4
L4:
  lexical_state_set index=1
  constant_integer value=1
  pop
  lexical_state_restore index=0
  global name="@", slot=1
  undef
  jump to=L5
L5:
  end
EOI
