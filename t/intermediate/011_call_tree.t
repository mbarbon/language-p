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
  jump to=L2
L2:
  end
# foo
L1:
  lexical_state_set index=1
  return context=0 (make_list (print context=0 (global name="STDOUT", slot=7), (make_list (concat_assign context=4 (concat_assign context=4 (concat_assign context=4 (fresh_string value=""), (constant_string value="ok ")), (array_element create=0, context=4 (constant_integer value=0), (lexical index=0, slot=2))), (constant_string value="\x0a")))))
  jump to=L2
L2:
  end
EOI
