#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_and_diff( <<'EOP', <<'EOI' );
sub foo {
    print "ok $_[0]\n";
}

foo( 1 );
EOP
# main
L1:
  constant_integer 1
  make_list count=1
  global name=foo, slot=4
  call context=2
  pop
  end
# foo
L1:
  global name=STDOUT, slot=7
  fresh_string ""
  constant_string "ok "
  concat_assign
  constant_integer 0
  lexical level=0, lexical=array(_)
  array_element
  concat_assign
  constant_string "\x0a"
  concat_assign
  make_list count=2
  print
  make_list count=1
  return
  end
EOI
