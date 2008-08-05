#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
print 1, 2 or die;
EOP
--- !parsetree:BinOp
left: !parsetree:Print
  arguments:
    - !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 1
    - !parsetree:Number
      flags: NUM_INTEGER
      type: number
      value: 2
  filehandle: ~
  function: print
op: or
right: !parsetree:Overridable
  arguments: ~
  function: die
EOE
