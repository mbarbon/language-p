#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestParser qw(:all);

parse_and_diff_yaml( <<'EOP', <<'EOE' );
package x;
EOP
--- !parsetree:Package
name: x
EOE

parse_and_diff_yaml( <<'EOP', <<'EOE' );
$x;
{
    package x;
    $x;
    package z
}
$x;
package y;
$x;
EOP
--- !parsetree:Symbol
context: CXT_VOID
name: x
sigil: $
--- !parsetree:Block
lines:
  - !parsetree:Package
    name: x
  - !parsetree:Symbol
    context: CXT_VOID
    name: x::x
    sigil: $
  - !parsetree:Package
    name: z
--- !parsetree:Symbol
context: CXT_VOID
name: x
sigil: $
--- !parsetree:Package
name: y
--- !parsetree:Symbol
context: CXT_VOID
name: y::x
sigil: $
EOE
