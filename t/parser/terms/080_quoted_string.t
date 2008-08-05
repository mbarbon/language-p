#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 18;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"";
EOP
--- !parsetree:Constant
type: string
value: ''
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"\"";
EOP
--- !parsetree:Constant
type: string
value: '"'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
'\'';
EOP
--- !parsetree:Constant
type: string
value: "'"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
'\n';
EOP
--- !parsetree:Constant
type: string
value: \n
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"abcdefg";
EOP
--- !parsetree:Constant
type: string
value: abcdefg
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"x\n";
EOP
--- !parsetree:Constant
type: string
value: "x\n"
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"ab$a $b";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    type: string
    value: ab
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: $
  - !parsetree:Constant
    type: string
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
    type: string
    value: ab
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: a
    sigil: $
  - !parsetree:Constant
    type: string
    value: cd
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"a$^E b";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    type: string
    value: a
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: "\x05"
    sigil: $
  - !parsetree:Constant
    type: string
    value: ' b'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
"a${^Foo} b";
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    type: string
    value: a
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: "\x06oo"
    sigil: $
  - !parsetree:Constant
    type: string
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
  type: string
  value: 1
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Symbol
  context: CXT_SCALAR|CXT_LVALUE
  name: x
  sigil: $
op: =
right: !parsetree:Number
  flags: NUM_INTEGER
  type: number
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
      type: string
      value: ab
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: a
      sigil: $
    - !parsetree:Constant
      type: string
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
        type: string
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
<foo >;
EOP
--- !parsetree:Glob
arguments:
  - !parsetree:Constant
    type: string
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
        type: string
        value: "'"
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: x
        sigil: $
      - !parsetree:Constant
        type: string
        value: ' '
      - !parsetree:Symbol
        context: CXT_SCALAR
        name: y
        sigil: $
      - !parsetree:Constant
        type: string
        value: "'"
context: CXT_VOID
function: glob
EOE
