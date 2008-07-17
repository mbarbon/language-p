package Language::P::Opcodes;

use strict;
use warnings;
use Exporter 'import';

use Language::P::Value::StringNumber;
use Language::P::Value::Array;
use Language::P::Value::List;

our @EXPORT_OK = qw(o);

sub o {
    my( $name, %args ) = @_;

    die "Invalid opcode '$name'"
        unless defined $Language::P::Opcodes::{"o_$name"};
    my $fun = *{$Language::P::Opcodes::{"o_$name"}}{CODE};
    die "Invalid opcode '$name'"
        unless defined $fun;

    return { %args,
             function => $fun,
             op_name  => $name,
             };
}

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

sub o_stringify {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->_stack};

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { string => $v->as_string } );

    return $pc + 1;
}

sub _make_binary_op {
    my( $op ) = @_;

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->%s %s $v2->%s;

    push @{$runtime->_stack},
         Language::P::Value::StringNumber->new( { %s => $r } );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{convert}, $op->{operator}, $op->{convert},
        $op->{new_type};
}

_make_binary_op( $_ ) foreach
  ( { name     => 'o_add',
      convert  => 'as_integer',
      operator => '+',
      new_type => 'integer',
      },
    { name     => 'o_subtract',
      convert  => 'as_integer',
      operator => '-',
      new_type => 'integer',
      },
    { name     => 'o_multiply',
      convert  => 'as_integer',
      operator => '*',
      new_type => 'integer',
      },
    { name     => 'o_divide',
      convert  => 'as_integer',
      operator => '/',
      new_type => 'integer',
      },
    { name     => 'o_modulus',
      convert  => 'as_integer',
      operator => '%',
      new_type => 'integer',
      },
    { name     => 'o_concat',
      convert  => 'as_string',
      operator => '.',
      new_type => 'string',
      },
    );

sub o_start_call {
    my( $op, $runtime, $pc ) = @_;
    push @{$runtime->_stack}, Language::P::Value::List->new;

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

sub _make_compare {
    my( $op ) = @_;

    my $ret = $op->{new_type} eq 'int' ?
                  '$r' :
                  'Language::P::Value::StringNumber->new( { integer => $r } )';

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->_stack};
    my $v2 = pop @{$runtime->_stack};
    my $r = $v1->%s %s $v2->%s ? 1 : 0;

    push @{$runtime->_stack}, %s;

    return $pc + 1;
}
EOT
        $op->{name}, $op->{convert}, $op->{operator}, $op->{convert},
        $ret;
}

_make_compare( $_ ) foreach
  ( { name     => 'o_compare_i_lt_int',
      convert  => 'as_integer',
      operator => '<',
      new_type => 'int',
      },
    { name     => 'o_compare_i_le_int',
      convert  => 'as_integer',
      operator => '<=',
      new_type => 'int',
      },
    { name     => 'o_compare_i_eq_int',
      convert  => 'as_integer',
      operator => '==',
      new_type => 'int',
      },
    { name     => 'o_compare_i_ge_int',
      convert  => 'as_integer',
      operator => '>=',
      new_type => 'int',
      },
    { name     => 'o_compare_i_gt_int',
      convert  => 'as_integer',
      operator => '>',
      new_type => 'int',
      },

    { name     => 'o_compare_i_eq_scalar',
      convert  => 'as_integer',
      operator => '==',
      new_type => 'scalar',
      },

    { name     => 'o_compare_i_ne_scalar',
      convert  => 'as_integer',
      operator => '!=',
      new_type => 'scalar',
      },
    { name     => 'o_compare_s_eq_int',
      convert  => 'as_string',
      operator => 'eq',
      new_type => 'int',
      },
    { name     => 'o_compare_s_ne_int',
      convert  => 'as_string',
      operator => 'ne',
      new_type => 'int',
      },

    { name     => 'o_compare_s_eq_scalar',
      convert  => 'as_string',
      operator => 'eq',
      new_type => 'scalar',
      },
    { name     => 'o_compare_s_ne_scalar',
      convert  => 'as_string',
      operator => 'ne',
      new_type => 'scalar',
      },
    );

sub o_negate {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->_stack};

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => -$v->get_integer } );

    return $pc + 1;
}

sub o_not {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->_stack};

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => !$v->as_boolean_int } );

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

sub o_unlink {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->_stack};
    my @args;

    for( my $it = $args->iterator; $it->next; ) {
        my $arg = $it->item;

        push @args, $arg->as_string;
    }

    my $ret = unlink @args;

    return Language::P::Value::StringNumber( { string => $ret } );
}

sub o_array_element {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->_stack};
    my $index = pop @{$runtime->_stack};

    push @{$runtime->_stack}, $array->get_item( $index->as_integer );

    return $pc + 1;
}

sub o_hash_element {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->_stack};
    my $key = pop @{$runtime->_stack};

    push @{$runtime->_stack}, $hash->get_item( $key->as_string );

    return $pc + 1;
}

sub o_array_size {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->_stack};

    push @{$runtime->_stack}, Language::P::Value::StringNumber->new( { integer => $array->get_count - 1 } );

    return $pc + 1;
}

1;
