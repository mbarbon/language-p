#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 11;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
q<$e>;
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: $e
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
q "$e";
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: $e
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qq();
EOP
--- !parsetree:Constant
context: CXT_VOID
flags: CONST_STRING
value: ''
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qq(ab${e}cdefg);
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: ab
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: e
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: cdefg
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qq(a(${e}(d)e\)f)g);
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: a(
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: e
    sigil: VALUE_SCALAR
  - !parsetree:Constant
    context: CXT_SCALAR
    flags: CONST_STRING
    value: (d)e)f)g
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qq '$e';
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Symbol
    context: CXT_SCALAR
    name: e
    sigil: VALUE_SCALAR
context: CXT_VOID
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qx($e);
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:QuotedString
  components:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: e
      sigil: VALUE_SCALAR
  context: CXT_SCALAR
op: OP_BACKTICK
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qx  # test
'$e';
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:Constant
  context: CXT_SCALAR
  flags: CONST_STRING
  value: $e
op: OP_BACKTICK
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qx#$e#;
EOP
--- !parsetree:UnOp
context: CXT_VOID
left: !parsetree:QuotedString
  components:
    - !parsetree:Symbol
      context: CXT_SCALAR
      name: e
      sigil: VALUE_SCALAR
  context: CXT_SCALAR
op: OP_BACKTICK
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qw!!;
EOP
--- !parsetree:List
context: CXT_VOID
expressions: []
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qw zaaa bbb
    eee fz;
EOP
--- !parsetree:List
context: CXT_VOID
expressions:
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_STRING
    value: aaa
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_STRING
    value: bbb
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_STRING
    value: eee
  - !parsetree:Constant
    context: CXT_VOID
    flags: CONST_STRING
    value: f
EOE
