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
  call context=2 (make_list (constant_integer value=1)), (global name="foo", slot=4)
  end
# foo
L1:
  return (make_list (print (make_list (global name="STDOUT", slot=7), (concat_assign (concat_assign (concat_assign (fresh_string value=""), (constant_string value="ok ")), (array_element (constant_integer value=0), (lexical index=0, slot=2))), (constant_string value="\x0a")))))
  end
EOI
