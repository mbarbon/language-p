#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 1;

generate_tree_and_diff( <<'EOP', <<'EOI' );
sub foo {
    print "ok $_[0]\n";
}

foo( 1 );
EOP
# main
L1: # scope=1
  lexical_state_set index=0
  call context=2 (make_array context=8 (constant_integer value=1)), (global context=4, name="foo", slot=4)
  jump to=L2
L2: # scope=0
  end
# foo
L1: # scope=1
  lexical_state_set index=1
  return context=1 (make_list context=8 (print context=1 (global context=4, name="STDOUT", slot=7), (make_array context=8 (concat_assign context=4 (concat_assign context=4 (concat_assign context=4 (fresh_string value=""), (constant_string value="ok ")), (array_element context=4, create=0 (constant_integer value=0), (lexical lexical_info={index=0, slot=VALUE_ARRAY}))), (constant_string value="\x0a")))))
EOI
