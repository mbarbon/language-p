#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
moo.boo
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Bareword
  type: string
  value: moo
op: .
right: !parsetree:Bareword
  type: string
  value: boo
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
moo'moo.boo::boo::::
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Bareword
  type: string
  value: moo::moo
op: .
right: !parsetree:Bareword
  type: string
  value: 'boo::boo::'
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
::moo.::boo
EOP
--- !parsetree:BinOp
context: CXT_VOID
left: !parsetree:Bareword
  type: string
  value: ::moo
op: .
right: !parsetree:Bareword
  type: string
  value: ::boo
EOE
