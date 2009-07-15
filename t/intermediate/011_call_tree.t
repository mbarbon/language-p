#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;

use lib qw(t/lib);
use TestIntermediate qw(:all);

generate_tree_and_diff( <<'EOP', <<'EOI' );
sub foo {
    print "ok $_[0]\n";
}

foo( 1 );
EOP
# main
L1:
  call context=2 (make_list (constant_integer 1)), (global name=foo, slot=4)
  end
# foo
L1:
  return (make_list (print (global name=STDOUT, slot=7), (make_list (concat_assign (concat_assign (concat_assign (fresh_string ""), (constant_string "ok ")), (array_element (constant_integer 0), (lexical lexical=array(_), level=0))), (constant_string "\x0a")))))
  end
EOI
