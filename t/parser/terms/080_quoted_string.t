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
    name: a
    sigil: $
  - !parsetree:Constant
    type: string
    value: ' '
  - !parsetree:Symbol
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
left: !parsetree:Symbol
  name: x
  sigil: $
op: =
right: !parsetree:Constant
  type: string
  value: 1
--- !parsetree:BinOp
left: !parsetree:Symbol
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
left: !parsetree:QuotedString
  components:
    - !parsetree:Constant
      type: string
      value: ab
    - !parsetree:Symbol
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
        name: x
        sigil: $
      - !parsetree:Constant
        type: string
        value: ' '
      - !parsetree:Symbol
        name: y
        sigil: $
function: glob
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<foo>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    name: foo
    sigil: '*'
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
function: glob
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<$x>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    name: x
    sigil: $
function: readline
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
<${x}>;
EOP
--- !parsetree:Overridable
arguments:
  - !parsetree:Symbol
    name: x
    sigil: $
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
        name: x
        sigil: $
      - !parsetree:Constant
        type: string
        value: ' '
      - !parsetree:Symbol
        name: y
        sigil: $
      - !parsetree:Constant
        type: string
        value: "'"
function: glob
EOE
