#!/usr/bin/perl -w

use strict;
use t::lib::TestIntermediate tests => 2;

generate_tree_and_diff( <<'EOP', <<'EOI' );
my @x;
push @x, @{$foo};
EOP
# main
L1:
  lexical_state_set index=0
  lexical_pad index=0, slot=VALUE_ARRAY
  set index=1, slot=VALUE_ARRAY (lexical_pad index=0, slot=VALUE_ARRAY)
  jump to=L2
L2:
  array_push context=CXT_VOID (get index=1, slot=VALUE_ARRAY), (make_array context=CXT_LIST (dereference_array context=CXT_LIST (global context=CXT_SCALAR, name="foo", slot=VALUE_SCALAR)))
  jump to=L3
L3:
  end
EOI

generate_tree_and_diff( <<'EOP', <<'EOI' );
my( @x, @y );
sub foo {
    my( $x, $y ) = @_;

    return $x ? @x : @y;
}
EOP
# main
L1:
  lexical_state_set index=0
  make_list context=CXT_VOID (lexical_pad index=0, slot=VALUE_ARRAY), (lexical_pad index=1, slot=VALUE_ARRAY)
  jump to=L2
L2:
  end
# foo
L1:
  lexical_state_set index=1
  assign context=CXT_VOID (make_list context=CXT_LIST|CXT_LVALUE (lexical index=1, slot=VALUE_SCALAR), (lexical index=2, slot=VALUE_SCALAR)), (lexical index=0, slot=VALUE_ARRAY)
  jump_if_true to=L3 (lexical index=1, slot=VALUE_SCALAR)
  jump to=L4
L2:
  set index=4, slot=VALUE_ARRAY (make_list context=CXT_LIST (get index=3, slot=VALUE_ARRAY))
  lexical_clear index=2, slot=VALUE_SCALAR
  lexical_clear index=1, slot=VALUE_SCALAR
  return context=CXT_CALLER (get index=4, slot=VALUE_ARRAY)
L3:
  set index=1, slot=VALUE_ARRAY (lexical_pad index=0, slot=VALUE_ARRAY)
  set index=3, slot=VALUE_ARRAY (get index=1, slot=VALUE_ARRAY)
  jump to=L2
L4:
  set index=2, slot=VALUE_ARRAY (lexical_pad index=1, slot=VALUE_ARRAY)
  set index=3, slot=VALUE_ARRAY (get index=2, slot=VALUE_ARRAY)
  jump to=L2
EOI