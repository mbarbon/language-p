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
  call context=2 (make_array context=8 (constant_integer value=1)), (global context=4, name="foo", slot=4)
  jump to=L2
L2:
  end
# foo
L1:
  lexical_state_set index=1
  return context=1 (make_list context=8 (print context=1 (global context=4, name="STDOUT", slot=7), (make_array context=8 (concat_assign context=4 (concat_assign context=4 (concat_assign context=4 (fresh_string value=""), (constant_string value="ok ")), (array_element context=4, create=0 (constant_integer value=0), (lexical index=0, slot=2))), (constant_string value="\x0a")))))
EOI
