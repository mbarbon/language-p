package Language::P::Toy::Opcodes;

use strict;
use warnings;
use Exporter 'import';

use Language::P::Toy::Value::StringNumber;
use Language::P::Toy::Value::Reference;
use Language::P::Toy::Value::Array;
use Language::P::Toy::Value::List;
use Language::P::ParseTree qw(:all);

use Language::P::Toy::Opcodes::Regex qw(:opcodes);

our @EXPORT_OK = qw(o);

sub o {
    my( $name, %args ) = @_;

    Carp::confess "Invalid opcode '$name'"
        unless defined $Language::P::Toy::Opcodes::{"o_$name"};
    my $fun = *{$Language::P::Toy::Opcodes::{"o_$name"}}{CODE};
    Carp::confess "Invalid opcode '$name'"
        unless defined $fun;

    return { %args,
             function => $fun,
             op_name  => $name,
             };
}

sub _context {
    my( $op, $runtime ) = @_;
    my $cxt = $op ? $op->{context} : 0;

    return $cxt if $cxt && $cxt != CXT_CALLER;
    return $runtime->{_stack}[$runtime->{_frame} - 2][2];
}

sub o_noop {
    my( $op, $runtime, $pc ) = @_;

    return $pc + 1;
}

sub o_dup {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->{_stack}->[-1];

    push @{$runtime->{_stack}}, $value;

    return $pc + 1;
}

sub o_pop {
    my( $op, $runtime, $pc ) = @_;

    pop @{$runtime->{_stack}};

    return $pc + 1;
}

sub o_print {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};

    my $fh = $args->get_item( 0 );
    for( my $iter = $args->iterator_from( 1 ); $iter->next; ) {
        $fh->write( $iter->item );
    }

    # HACK
    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( { integer => 1 } );

    return $pc + 1;
}

sub o_constant {
    my( $op, $runtime, $pc ) = @_;
    push @{$runtime->{_stack}}, $op->{value};

    return $pc + 1;
}

sub o_stringify {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( { string => $v->as_string } );

    return $pc + 1;
}

sub _make_binary_op {
    my( $op ) = @_;

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->{_stack}};
    my $v2 = pop @{$runtime->{_stack}};
    my $r = $v1->%s %s $v2->%s;

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::StringNumber->new( { %s => $r } );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{convert}, $op->{operator}, $op->{convert},
        $op->{new_type};
}

_make_binary_op( $_ ) foreach
  ( { name     => 'o_add',
      convert  => 'as_float',
      operator => '+',
      new_type => 'float',
      },
    { name     => 'o_subtract',
      convert  => 'as_float',
      operator => '-',
      new_type => 'float',
      },
    { name     => 'o_multiply',
      convert  => 'as_float',
      operator => '*',
      new_type => 'float',
      },
    { name     => 'o_divide',
      convert  => 'as_float',
      operator => '/',
      new_type => 'float',
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

sub o_start_list {
    my( $op, $runtime, $pc ) = @_;
    push @{$runtime->{_stack}}, 'list_mark';

    return $pc + 1;
}

sub o_end_list {
    my( $op, $runtime, $pc ) = @_;
    my $st = $runtime->{_stack};

    # find the mark
    my $i;
    for( $i = $#$st; $i >= 0; --$i ) {
        last if $st->[$i] eq 'list_mark';
    }
    # create the list
    my $list = $st->[$i] = Language::P::Toy::Value::List->new;
    for( my $j = $i + 1; $j <= $#$st; ++$j ) {
        $list->push( $st->[$j] );
    }
    # clear the stack
    $#$st = $i;

    return $pc + 1;
}

sub o_end {
    my( $op, $runtime, $pc ) = @_;

    return -1;
}

sub o_want {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = _context( undef, $runtime );
    my $v;

    if( $cxt == CXT_VOID ) {
        $v = Language::P::Toy::Value::StringNumber->new;
    } elsif( $cxt == CXT_SCALAR ) {
        $v = Language::P::Toy::Value::StringNumber->new( { string => '' } );
    } elsif( $cxt == CXT_LIST ) {
        $v = Language::P::Toy::Value::StringNumber->new( { integer => 1 } );
    } else {
        die "Unknow context $cxt";
    }
    push @{$runtime->{_stack}}, $v;

    return $pc + 1;
}

sub o_call {
    my( $op, $runtime, $pc ) = @_;
    my $sub = pop @{$runtime->{_stack}};

    $sub->call( $runtime, $pc, _context( $op, $runtime ) );

    return 0;
}

sub o_return {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = _context( undef, $runtime );
    my $rv = $runtime->{_stack}->[-1];
    my $rpc = $runtime->call_return;

    if( $cxt == CXT_SCALAR ) {
        if( $rv->get_count > 0 ) {
            push @{$runtime->{_stack}}, $rv->get_item( $rv->get_count - 1 )
                                           ->as_scalar;
        } else {
            push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new;
        }
    } elsif( $cxt == CXT_LIST ) {
        push @{$runtime->{_stack}}, $rv;
    }

    return $rpc + 1;
}

sub o_glob {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->symbol_table->get_symbol( $op->{name}, '*',
                                                    $op->{create} );

    push @{$runtime->{_stack}}, $value;

    return $pc + 1;
}

sub o_lexical {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}];

    push @{$runtime->{_stack}}, $value;

    return $pc + 1;
}

sub o_lexical_set {
    my( $op, $runtime, $pc ) = @_;
    my $value = pop @{$runtime->{_stack}};

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = $value;

    return $pc + 1;
}

sub o_lexical_clear {
    my( $op, $runtime, $pc ) = @_;

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = undef;

    return $pc + 1;
}

sub o_lexical_pad {
    my( $op, $runtime, $pc ) = @_;
    my $pad = $runtime->{_stack}->[$runtime->{_frame} - 1];

    push @{$runtime->{_stack}}, $pad->values->[$op->{index}];

    return $pc + 1;
}

sub o_parameter_index {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->{_stack}->[$runtime->{_frame} - 3]->get_item( $op->{index} );

    push @{$runtime->{_stack}}, $value;

    return $pc + 1;
}

sub o_jump {
    my( $op, $runtime, $pc ) = @_;

    return $op->{to};
}

sub o_jump_if_eq_immed {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->{_stack}};

    return $v1 == $op->{value} ? $op->{to} : $pc + 1;
}

sub o_jump_if_false {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->{_stack}};

    return !$v1->as_boolean_int ? $op->{to} : $pc + 1;
}

sub o_jump_if_true {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->{_stack}};

    return $v1->as_boolean_int ? $op->{to} : $pc + 1;
}

sub _make_compare {
    my( $op ) = @_;

    my $ret = $op->{new_type} eq 'int' ?
                  '$r' :
                  'Language::P::Toy::Value::StringNumber->new( { integer => $r } )';

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->{_stack}};
    my $v2 = pop @{$runtime->{_stack}};
    my $r = $v1->%s %s $v2->%s ? 1 : 0;

    push @{$runtime->{_stack}}, %s;

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

    { name     => 'o_compare_i_le_scalar',
      convert  => 'as_integer',
      operator => '<=',
      new_type => 'scalar',
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

    { name     => 'o_compare_f_lt_int',
      convert  => 'as_float',
      operator => '<',
      new_type => 'int',
      },
    { name     => 'o_compare_f_le_int',
      convert  => 'as_float',
      operator => '<=',
      new_type => 'int',
      },
    { name     => 'o_compare_f_eq_int',
      convert  => 'as_float',
      operator => '==',
      new_type => 'int',
      },
    { name     => 'o_compare_f_ge_int',
      convert  => 'as_float',
      operator => '>=',
      new_type => 'int',
      },
    { name     => 'o_compare_f_gt_int',
      convert  => 'as_float',
      operator => '>',
      new_type => 'int',
      },

    { name     => 'o_compare_f_le_scalar',
      convert  => 'as_float',
      operator => '<=',
      new_type => 'scalar',
      },
    { name     => 'o_compare_f_eq_scalar',
      convert  => 'as_float',
      operator => '==',
      new_type => 'scalar',
      },
    { name     => 'o_compare_f_ne_scalar',
      convert  => 'as_float',
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
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( { float => -$v->as_float } );

    return $pc + 1;
}

sub o_abs {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( { float => abs $v->as_float } );

    return $pc + 1;
}

sub o_not {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( { integer => !$v->as_boolean_int } );

    return $pc + 1;
}

sub o_assign {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->{_stack}};
    my $v2 = pop @{$runtime->{_stack}};

    $v1->assign( $v2 );

    return $pc + 1;
}

sub o_glob_slot_create {
    my( $op, $runtime, $pc ) = @_;
    my $glob = pop @{$runtime->{_stack}};
    my $slot = $op->{slot};

    push @{$runtime->{_stack}}, $glob->get_or_create_slot( $slot, $op->{create} );

    return $pc + 1;
}

sub o_glob_slot {
    my( $op, $runtime, $pc ) = @_;
    my $glob = pop @{$runtime->{_stack}};
    my $slot = $op->{slot};

    push @{$runtime->{_stack}}, $glob->get_slot( $slot, $op->{create} );

    return $pc + 1;
}

sub o_glob_slot_set {
    my( $op, $runtime, $pc ) = @_;

    my $value = pop @{$runtime->{_stack}};
    my $glob = pop @{$runtime->{_stack}};
    my $slot = $op->{slot};

    $glob->set_slot( $slot, $value );

    return $pc + 1;
}

sub o_unlink {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my @args;

    for( my $it = $args->iterator; $it->next; ) {
        my $arg = $it->item;

        push @args, $arg->as_string;
    }

    my $ret = unlink @args;

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber( { integer => $ret } );
    return $pc + 1;
}

sub o_backtick {
    my( $op, $runtime, $pc ) = @_;
    my $arg = pop @{$runtime->{_stack}};
    my $command = $arg->as_string;

    # context
    my $ret = `$command`;

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( { string => $ret } );

    return $pc + 1;
}

sub o_array_element {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};
    my $index = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $array->get_item( $index->as_integer );

    return $pc + 1;
}

sub o_hash_element {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $key = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $hash->get_item( $key->as_string );

    return $pc + 1;
}

sub o_array_size {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( { integer => $array->get_count - 1 } );

    return $pc + 1;
}

sub o_reference {
    my( $op, $runtime, $pc ) = @_;
    my $value = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Reference->new( { reference => $value } );

    return $pc + 1;
}

sub o_dereference_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $ref = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $ref->dereference_scalar;

    return $pc + 1;
}

sub o_defined {
    my( $op, $runtime, $pc ) = @_;
    my $value = pop @{$runtime->{_stack}};
    my $defined = $value->is_defined;

    push @{$runtime->{_stack}}, $defined ?
             Language::P::Toy::Value::StringNumber->new( { integer => 1 } ) :
             Language::P::Toy::Value::StringNumber->new( { string => '' } );

    return $pc + 1;
}

1;
