#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 30;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"";
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: ''
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\"";
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: '"'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
'\'';
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: "'"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
'\n';
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: \n
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"abcdefg";
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: abcdefg
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"x\n";
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: "x\n"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\0\100\77";
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: "\0@?"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\xg\x20F\x1g";
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: "\0g F\x01g"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"x\c@\cx";
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: "x\0\x18"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"ab$a $b";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ab
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ' '
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: b
    sigil: VALUE_SCALAR
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"ab${a}cd";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ab
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: cd
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"a$^E b";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: a
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: "\x05"
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ' b'
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"a${^Foo} b";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: a
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: "\x06oo"
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ' b'
context: CXT_VOID
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
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: 1
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: VALUE_SCALAR
op: OP_ASSIGN
right: !parsetree:Constant
  context: CXT_SCALAR
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
      context: CXT_SCALAR
      flags: CONST_STRING
      value: ab
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: VALUE_SCALAR
    - !parsetree:Constant
      context: CXT_SCALAR
      flags: CONST_STRING
      value: cd
  context: CXT_SCALAR
op: OP_BACKTICK
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
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: ' '
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: y
        sigil: VALUE_SCALAR
    context: CXT_SCALAR
context: CXT_VOID
function: OP_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<foo>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_READLINE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<foo::moo'boo>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo::moo::boo
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_READLINE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<foo'boo>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: foo::boo
    sigil: VALUE_GLOB
context: CXT_VOID
function: OP_READLINE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<foo >;
EOP
--- !parsetree:Glob
arguments:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: 'foo '
context: CXT_VOID
function: OP_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<$x>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_READLINE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<${x}>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_SCALAR
context: CXT_VOID
function: OP_READLINE
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<'$x $y'>;
EOP
--- !parsetree:Glob
arguments:
  - !parsetree:QuotedString
    components:
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: "'"
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: x
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: ' '
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: y
        sigil: VALUE_SCALAR
      - !parsetree:Constant
        context: CXT_SCALAR
        flags: CONST_STRING
        value: "'"
    context: CXT_SCALAR
context: CXT_VOID
function: OP_GLOB
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"$#x";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Dereference
    context: CXT_SCALAR
    left: !parsetree:Symbol
      context: CXT_SCALAR
      name: x
      sigil: VALUE_ARRAY
    op: OP_ARRAY_LENGTH
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"$#{2}";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Dereference
    context: CXT_SCALAR
    left: !parsetree:Symbol
      context: CXT_SCALAR
      name: 2
      sigil: VALUE_ARRAY
    op: OP_ARRAY_LENGTH
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"$# {2}";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: '#'
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ' {2}'
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"$# ";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: '#'
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ' '
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"$ x";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: x
    sigil: VALUE_SCALAR
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
" $@";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ' '
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: '@'
    sigil: VALUE_SCALAR
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
" $ @";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ' '
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: '@'
    sigil: VALUE_SCALAR
context: CXT_VOID
EOE
