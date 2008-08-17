#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 20;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"";
EOP
--- !parsetree:Constant
flags: CONST_STRING
value: ''
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\"";
EOP
--- !parsetree:Constant
flags: CONST_STRING
value: '"'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
'\'';
EOP
--- !parsetree:Constant
flags: CONST_STRING
value: "'"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
'\n';
EOP
--- !parsetree:Constant
flags: CONST_STRING
value: \n
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"abcdefg";
EOP
--- !parsetree:Constant
flags: CONST_STRING
value: abcdefg
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"x\n";
EOP
--- !parsetree:Constant
flags: CONST_STRING
value: "x\n"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"ab$a $b";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    flags: CONST_STRING
    value: ab
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: $
  - !parsetree:Constant
    flags: CONST_STRING
    value: ' '
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"ab${a}cd";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    flags: CONST_STRING
    value: ab
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: $
  - !parsetree:Constant
    flags: CONST_STRING
    value: cd
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"a$^E b";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    flags: CONST_STRING
    value: a
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: "\x05"
    sigil: $
  - !parsetree:Constant
    flags: CONST_STRING
    value: ' b'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"a${^Foo} b";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    flags: CONST_STRING
    value: a
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: "\x06oo"
    sigil: $
  - !parsetree:Constant
    flags: CONST_STRING
    value: ' b'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x = "1";
$x = 1;
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: $
op: =
right: !parsetree:Constant
  flags: CONST_STRING
  value: 1
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: $
op: =
right: !parsetree:Constant
  flags: CONST_NUMBER|NUM_INTEGER
  value: 1
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
`ab${a}cd`;
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:QuotedString
  components:
    - !parsetree:Constant
      flags: CONST_STRING
      value: ab
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: $
    - !parsetree:Constant
      flags: CONST_STRING
      value: cd
op: backtick
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<$x $y>;
EOP
--- !parsetree:Glob
arguments:
  - !parsetree:QuotedString
    components:
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: x
        sigil: $
      - !parsetree:Constant
        flags: CONST_STRING
        value: ' '
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: y
        sigil: $
context: CXT_VOID
function: glob
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<foo>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: '*'
context: CXT_VOID
function: readline
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<foo::moo'boo>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo::moo::boo
    sigil: '*'
context: CXT_VOID
function: readline
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<foo'boo>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo::boo
    sigil: '*'
context: CXT_VOID
function: readline
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<foo >;
EOP
--- !parsetree:Glob
arguments:
  - !parsetree:Constant
    flags: CONST_STRING
    value: 'foo '
context: CXT_VOID
function: glob
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<$x>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: $
context: CXT_VOID
function: readline
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<${x}>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: $
context: CXT_VOID
function: readline
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<'$x $y'>;
EOP
--- !parsetree:Glob
arguments:
  - !parsetree:QuotedString
    components:
      - !parsetree:Constant
        flags: CONST_STRING
        value: "'"
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: x
        sigil: $
      - !parsetree:Constant
        flags: CONST_STRING
        value: ' '
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: y
        sigil: $
      - !parsetree:Constant
        flags: CONST_STRING
        value: "'"
context: CXT_VOID
function: glob
EOE
