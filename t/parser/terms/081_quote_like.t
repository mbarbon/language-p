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
type: string
value: $e
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
q "$e";
EOP
--- !parsetree:Constant
type: string
value: $e
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qq();
EOP
--- !parsetree:Constant
type: string
value: ''
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qq(ab${e}cdefg);
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    type: string
    value: ab
  - !parsetree:Symbol
    name: e
    sigil: $
  - !parsetree:Constant
    type: string
    value: cdefg
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qq(a(${e}(d)e\)f)g);
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Constant
    type: string
    value: a(
  - !parsetree:Symbol
    name: e
    sigil: $
  - !parsetree:Constant
    type: string
    value: (d)e)f)g
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qq '$e';
EOP
--- !parsetree:QuotedString
components:
  - !parsetree:Symbol
    name: e
    sigil: $
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qx($e);
EOP
--- !parsetree:UnOp
left: !parsetree:QuotedString
  components:
    - !parsetree:Symbol
      name: e
      sigil: $
op: backtick
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qx  # test
'$e';
EOP
--- !parsetree:UnOp
left: !parsetree:Constant
  type: string
  value: $e
op: backtick
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qx#$e#;
EOP
--- !parsetree:UnOp
left: !parsetree:QuotedString
  components:
    - !parsetree:Symbol
      name: e
      sigil: $
op: backtick
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qw!!;
EOP
--- !parsetree:List
expressions: []
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
qw zaaa bbb
    eee fz;
EOP
--- !parsetree:List
expressions:
  - !parsetree:Constant
    type: string
    value: aaa
  - !parsetree:Constant
    type: string
    value: bbb
  - !parsetree:Constant
    type: string
    value: eee
  - !parsetree:Constant
    type: string
    value: f
EOE
