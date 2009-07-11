#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use 5;
EOP
--- !parsetree:Use
import: ~
is_no: 0
package: ~
version: 5
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
no 5;
EOP
--- !parsetree:Use
import: ~
is_no: 1
package: ~
version: 5
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use strict;
EOP
--- !parsetree:Use
import: ~
is_no: 0
package: strict
version: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use 5.0 strict;
EOP
--- !parsetree:Use
import: ~
is_no: 0
package: strict
version: 5.0
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use strict 5.0;
EOP
--- !parsetree:Use
import: ~
is_no: 0
package: strict
version: 5.0
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use strict 5.0 'vars', 'refs';
EOP
--- !parsetree:Use
import: !parsetree:List
  expressions:
    - !parsetree:Constant
      flags: CONST_STRING
      value: vars
    - !parsetree:Constant
      flags: CONST_STRING
      value: refs
is_no: 0
package: strict
version: 5.0
EOE
