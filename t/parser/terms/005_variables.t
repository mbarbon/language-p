#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 15;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@foo
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
@'foo
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
@'foo
EOP
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: x
warnings: ~
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: VALUE_ARRAY
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$::foo'moo::::boo::::
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: 'foo::moo::::boo::::'
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$#foo
EOP
--- !parsetree:Dereference
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR
  name: foo
  sigil: VALUE_ARRAY
op: OP_ARRAY_LENGTH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
%foo
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: VALUE_HASH
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
*foo
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: foo
sigil: VALUE_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$_
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: _
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
$_
EOP
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: x
warnings: ~
--- !parsetree:Symbol
context: CXT_VOID
name: _
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$#
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: '#'
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$^E
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: "\x05"
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${^F}
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: "\x06"
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
${^F}
EOP
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: x
warnings: ~
--- !parsetree:Symbol
context: CXT_VOID
name: "\x06"
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
${^Foo}
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: "\x06oo"
sigil: VALUE_SCALAR
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
$0;
$1;
$12;
$012;
EOP
--- !parsetree:LexicalState
changed: CHANGED_PACKAGE
hints: 0
package: x
warnings: ~
--- !parsetree:Symbol
context: CXT_VOID
name: 0
sigil: VALUE_SCALAR
--- !parsetree:Symbol
context: CXT_VOID
name: 1
sigil: VALUE_SCALAR
--- !parsetree:Symbol
context: CXT_VOID
name: 12
sigil: VALUE_SCALAR
--- !parsetree:Symbol
context: CXT_VOID
name: 012
sigil: VALUE_SCALAR
EOE
