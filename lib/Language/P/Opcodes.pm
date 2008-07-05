package Language::P::Opcodes;

use strict;
use warnings;

use Language::P::Value::StringNumber;
use Language::P::Value::Array;
use Language::P::Value::List;

sub o_dup {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->_stack->[-1];

    push @{$runtime->_stack}, $value;

    return $pc + 1;
}

sub o_print {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->_stack};

    my $fh = $args->get_item( 0 );
    for( my $iter = $args->iterator_from( 1 ); $iter->next; ) {
        $fh->write( $iter->item );
    }

    # HACK
    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => 1 } );

    return $pc + 1;
}

sub o_constant {
    my( $op, $runtime, $pc ) = @_;
    push @{$runtime->_stack}, $op->{value};

    return $pc + 1;
}

sub o_push_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $value = pop @{$runtime->_stack};
    $runtime->_stack->[-1]->push( $value );

    return $pc + 1;
}

sub o_add {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer + $v2->as_integer;

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $r } );

    return $pc + 1;
}

sub o_subtract {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer - $v2->as_integer;

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $r } );

    return $pc + 1;
}

sub o_multiply {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer * $v2->as_integer;

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $r } );

    return $pc + 1;
}

sub o_divide {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer / $v2->as_integer;

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $r } );

    return $pc + 1;
}

sub o_modulus {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer % $v2->as_integer;

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $r } );

    return $pc + 1;
}

sub o_start_call {
    my( $op, $runtime, $pc ) = @_;
    push @{$runtime->_stack}, Language::P::Value::Array->new;

    return $pc + 1;
}

sub o_start_list {
    my( $op, $runtime, $pc ) = @_;
    push @{$runtime->_stack}, Language::P::Value::List->new;

    return $pc + 1;
}

sub o_end {
    my( $op, $runtime, $pc ) = @_;

    return -1;
}

sub o_call {
    my( $op, $runtime, $pc ) = @_;
    my $sub = pop @{$runtime->_stack};

    $sub->call( $runtime, $pc );

    return 0;
}

sub o_return {
    my( $op, $runtime, $pc ) = @_;
    my $rv = $runtime->_stack->[-1];
    my $rpc = $runtime->_stack->[$runtime->_frame - 2][0];
    my $bytecode = $runtime->_stack->[$runtime->_frame - 2][1];

    $runtime->set_bytecode( $bytecode );
    $runtime->pop_frame;

    # FIXME context handling, assume scalar for now
    if( 1 ) {
        push @{$runtime->_stack}, $rv->get_item( $rv->get_count - 1 )
                                      ->as_scalar;
    }

    return $rpc + 1;
}

sub o_glob {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->symbol_table->get_symbol( $op->{name}, '*',
                                                    $op->{create} );

    push @{$runtime->_stack}, $value;

    return $pc + 1;
}

sub o_lexical {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->_stack->[$runtime->_frame - 3 - $op->{index}];

    push @{$runtime->_stack}, $value;

    return $pc + 1;
}

sub o_lexical_pad {
    my( $op, $runtime, $pc ) = @_;
    my $pad = $runtime->_stack->[$runtime->_frame - 1];

    push @{$runtime->_stack}, $pad->values->[$op->{index}];

    return $pc + 1;
}

sub o_parameter_index {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->_stack->[$runtime->_frame - 3]->get_item( $op->{index} );

    push @{$runtime->_stack}, $value;

    return $pc + 1;
}

sub o_jump {
    my( $op, $runtime, $pc ) = @_;

    return $op->{to};
}

sub o_jump_if_eq_immed {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};

    return $v1 == $op->{value} ? $op->{to} : $pc + 1;
}

sub o_jump_if_false {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};

    return !$v1->as_boolean_int ? $op->{to} : $pc + 1;
}

sub o_jump_if_true {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};

    return $v1->as_boolean_int ? $op->{to} : $pc + 1;
}

sub o_compare_i_lt_int {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer < $v2->as_integer ? 1 : 0;

    push @{$runtime->_stack}, $r;

    return $pc + 1;
}

sub o_compare_i_gt_int {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer > $v2->as_integer ? 1 : 0;

    push @{$runtime->_stack}, $r;

    return $pc + 1;
}

sub o_compare_i_eq_int {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer == $v2->as_integer ? 1 : 0;

    push @{$runtime->_stack}, $r;

    return $pc + 1;
}

sub o_compare_i_eq_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer == $v2->as_integer ? 1 : 0;

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $r } );

    return $pc + 1;
}

sub o_compare_i_ne_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer != $v2->as_integer ? 1 : 0;

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $r } );

    return $pc + 1;
}

sub o_compare_i_le_int {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer <= $v2->as_integer ? 1 : 0;

    push @{$runtime->_stack}, $r;

    return $pc + 1;
}

sub o_compare_i_ge_int {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_integer >= $v2->as_integer ? 1 : 0;

    push @{$runtime->_stack}, $r;

    return $pc + 1;
}

sub o_compare_s_eq_int {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_string eq $v2->as_string ? 1 : 0;

    push @{$runtime->_stack}, $r;

    return $pc + 1;
}

sub o_compare_s_ne_int {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_string ne $v2->as_string ? 1 : 0;

    push @{$runtime->_stack}, $r;

    return $pc + 1;
}

sub o_compare_s_eq_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_string eq $v2->as_string ? 1 : 0;

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $r } );

    return $pc + 1;
}

sub o_compare_s_ne_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->as_string ne $v2->as_string ? 1 : 0;

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $r } );

    return $pc + 1;
}

sub o_assign {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};

    $v1->assign( $v2 );

    return $pc + 1;
}

sub o_glob_slot_create {
    my( $op, $runtime, $pc ) = @_;
    my $glob = pop @{$runtime->_stack};
    my $slot = $op->{slot};

    push @{$runtime->_stack}, $glob->get_or_create_slot( $slot, $op->{create} );

    return $pc + 1;
}

sub o_glob_slot {
    my( $op, $runtime, $pc ) = @_;
    my $glob = pop @{$runtime->_stack};
    my $slot = $op->{slot};

    push @{$runtime->_stack}, $glob->get_slot( $slot, $op->{create} );

    return $pc + 1;
}

1;
