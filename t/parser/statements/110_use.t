#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 8;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use 5;
EOP
--- !parsetree:Use
import: ~
is_no: 0
lexical_state: !parsetree:LexicalState
  changed: CHANGED_ALL
  hints: 0
  package: main
  warnings: ~
package: ~
version: 5
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
no 5;
EOP
--- !parsetree:Use
import: ~
is_no: 1
lexical_state: !parsetree:LexicalState
  changed: CHANGED_ALL
  hints: 0
  package: main
  warnings: ~
package: ~
version: 5
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use strict;
EOP
--- !parsetree:Use
import: ~
is_no: 0
lexical_state: !parsetree:LexicalState
  changed: CHANGED_ALL
  hints: 0
  package: main
  warnings: ~
package: strict
version: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package X;
use strict;
EOP
--- !parsetree:Use
import: ~
is_no: 0
lexical_state: !parsetree:LexicalState
  changed: CHANGED_ALL
  hints: 0
  package: X
  warnings: ~
package: strict
version: ~
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: X
warnings: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use 5.0 strict;
EOP
--- !parsetree:Use
import: ~
is_no: 0
lexical_state: !parsetree:LexicalState
  changed: CHANGED_ALL
  hints: 0
  package: main
  warnings: ~
package: strict
version: 5.0
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use strict 5.0;
EOP
--- !parsetree:Use
import: ~
is_no: 0
lexical_state: !parsetree:LexicalState
  changed: CHANGED_ALL
  hints: 0
  package: main
  warnings: ~
package: strict
version: 5.0
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use strict 'vars';
EOP
--- !parsetree:Use
import:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_STRING
    value: vars
is_no: 0
lexical_state: !parsetree:LexicalState
  changed: CHANGED_ALL
  hints: 0
  package: main
  warnings: ~
package: strict
version: ~
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
use strict 5.0 'vars', 'refs';
EOP
--- !parsetree:Use
import:
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_STRING
    value: vars
  - !parsetree:Constant
    context: CXT_LIST
    flags: CONST_STRING
    value: refs
is_no: 0
lexical_state: !parsetree:LexicalState
  changed: CHANGED_ALL
  hints: 0
  package: main
  warnings: ~
package: strict
version: 5.0
EOE
