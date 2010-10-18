#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 4;

generate_and_diff( <<'EOP', <<'EOI' );
split /aa/, $_
EOP
# main
L1:
  constant_regex value=anoncode
  global context=4, name="_", slot=1
  rx_split arg_count=2, context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
split "aa", $_
EOP
# main
L1:
  constant_regex value=anoncode
  global context=4, name="_", slot=1
  rx_split arg_count=2, context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
split / /, $_
EOP
# main
L1:
  constant_regex value=anoncode
  global context=4, name="_", slot=1
  rx_split arg_count=2, context=2
  pop
  jump to=L2
L2:
  end
EOI

generate_and_diff( <<'EOP', <<'EOI' );
split ' ', $_
EOP
# main
L1:
  constant_regex value=anoncode
  global context=4, name="_", slot=1
  rx_split_skipspaces arg_count=2, context=2
  pop
  jump to=L2
L2:
  end
EOI
