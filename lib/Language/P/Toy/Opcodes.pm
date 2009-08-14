package Language::P::Toy::Opcodes;

use strict;
use warnings;
use Exporter 'import';

use Language::P::Toy::Value::StringNumber;
use Language::P::Toy::Value::Reference;
use Language::P::Toy::Value::Array;
use Language::P::Toy::Value::List;
use Language::P::Toy::Exception;
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

sub o_swap {
    my( $op, $runtime, $pc ) = @_;
    my $t = $runtime->{_stack}->[-1];

    $runtime->{_stack}->[-1] = $runtime->{_stack}->[-2];
    $runtime->{_stack}->[-2] = $t;

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
    my $fh = pop @{$runtime->{_stack}};

    for( my $iter = $args->iterator( $runtime ); $iter->next( $runtime ); ) {
        $fh->write( $runtime, $iter->item( $runtime ) );
    }

    # HACK
    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 1 } );

    return $pc + 1;
}

sub o_readline {
    my( $op, $runtime, $pc ) = @_;
    my $glob = pop @{$runtime->{_stack}};
    my $fh = $glob->get_slot( $runtime, 'io' );
    my $cxt = _context( $op, $runtime );

    if( $cxt == CXT_LIST ) {
        my $val = [ map Language::P::Toy::Value::Scalar->new_string( $runtime, $_ ),
                        @{$fh->read_lines( $runtime )} ];
        push @{$runtime->{_stack}}, Language::P::Toy::Value::List->new
                                        ( $runtime, { array => $val } );
    } else {
        my $val = $fh->read_line( $runtime );
        push @{$runtime->{_stack}}, Language::P::Toy::Value::Scalar
                                        ->new_string( $runtime, $val );
    }

    return $pc + 1;
}

sub o_constant {
    my( $op, $runtime, $pc ) = @_;
    push @{$runtime->{_stack}}, $op->{value};

    return $pc + 1;
}

sub o_fresh_string {
    my( $op, $runtime, $pc ) = @_;
    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new
                                    ( $runtime, { string => $op->{value} } );

    return $pc + 1;
}

sub _make_binary_op {
    my( $op ) = @_;

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};
    my $r = $vl->%s %s $vr->%s;

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::StringNumber->new( $runtime, { %s => $r } );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{convert}, $op->{operator}, $op->{convert},
        $op->{new_type};
    die $@ if $@;
}

sub _make_binary_op_assign {
    my( $op ) = @_;

    eval sprintf <<'EOT',
sub %s_assign {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = $runtime->{_stack}[-1];
    my $r = $vl->%s %s $vr->%s;

    $vl->set_%s( $runtime, $r );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{convert}, $op->{operator}, $op->{convert},
        $op->{new_type};
    die $@ if $@;
}

# fixme integer arithmetic
_make_binary_op( $_ ), _make_binary_op_assign( $_ ) foreach
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
    { name     => 'o_bit_or',
      convert  => 'as_integer',
      operator => '|',
      new_type => 'integer',
      },
    { name     => 'o_bit_and',
      convert  => 'as_integer',
      operator => '&',
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

sub o_make_list {
    my( $op, $runtime, $pc ) = @_;
    my $st = $runtime->{_stack};

    # create the list
    my $list = Language::P::Toy::Value::List->new( $runtime );
    if( $op->{count} ) {
        for( my $j = $#$st - $op->{count} + 1; $j <= $#$st; ++$j ) {
            $list->push_value( $runtime, $st->[$j] );
        }
        # clear the stack
        $#$st -= $op->{count} - 1;
        $st->[-1] = $list;
    } else {
        push @$st, $list;
    }

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
        $v = Language::P::Toy::Value::Undef->new( $runtime );
    } elsif( $cxt == CXT_SCALAR ) {
        $v = Language::P::Toy::Value::StringNumber->new( $runtime, { string => '' } );
    } elsif( $cxt == CXT_LIST ) {
        $v = Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 1 } );
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

sub o_call_method {
    my( $op, $runtime, $pc ) = @_;
    my $args = $runtime->{_stack}[-1];
    my $invocant = $args->get_item( $runtime, 0 );
    my $sub = $invocant->find_method( $runtime, $op->{method} );

    die "Can't find method $op->{method}" unless $sub;

    $sub->call( $runtime, $pc, _context( $op, $runtime ) );

    return 0;
}

sub o_find_method {
    my( $op, $runtime, $pc ) = @_;
    my $invocant = pop @{$runtime->{_stack}};
    my $sub = $invocant->find_method( $runtime, $op->{method} );

    push @{$runtime->{_stack}}, $sub || Language::P::Toy::Value::Undef->new( $runtime );

    return $pc + 1;
}

my $empty_list = Language::P::Toy::Value::List->new( undef );

sub o_return {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = _context( undef, $runtime );
    my $rv = $runtime->{_stack}->[-1];
    my $rpc = $runtime->call_return;

    if( $cxt == CXT_SCALAR ) {
        if( $rv->get_count( $runtime ) > 0 ) {
            push @{$runtime->{_stack}}, $rv->get_item( $runtime, $rv->get_count( $runtime ) - 1 )
                                           ->as_scalar( $runtime );
        } else {
            push @{$runtime->{_stack}}, Language::P::Toy::Value::Undef->new( $runtime );
        }
    } elsif( $cxt == CXT_LIST ) {
        push @{$runtime->{_stack}}, $rv;
    } elsif( $cxt == CXT_VOID ) {
        # it is easier to generate code if a subroutine
        # always returns a value (even if a dummy one)
        push @{$runtime->{_stack}}, $empty_list;
    }

    return $rpc + 1;
}

sub o_glob {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->symbol_table->get_symbol( $runtime, $op->{name}, '*',
                                                    $op->{create} );

    push @{$runtime->{_stack}}, $value;

    return $pc + 1;
}

sub o_lexical {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}]
                  ||= Language::P::Toy::Value::Undef->new( $runtime );

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

sub o_lexical_pad_clear {
    my( $op, $runtime, $pc ) = @_;
    my $pad = $runtime->{_stack}->[$runtime->{_frame} - 1];

    $pad->values->[$op->{index}] = undef;

    return $pc + 1;
}

sub o_parameter_index {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->{_stack}->[$runtime->{_frame} - 3]->get_item( $runtime, $op->{index} );

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

    return !$v1->as_boolean_int( $runtime ) ? $op->{to} : $pc + 1;
}

sub o_jump_if_true {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->{_stack}};

    return $v1->as_boolean_int( $runtime ) ? $op->{to} : $pc + 1;
}

sub o_jump_if_null {
    my( $op, $runtime, $pc ) = @_;
    my $v1 = pop @{$runtime->{_stack}};

    return !defined $v1 ? $op->{to} : $pc + 1;
}

sub _make_cond_jump {
    my( $op ) = @_;

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};

    return $vl->%s( $runtime ) %s $vr->%s( $runtime ) ? $op->{to} : $pc + 1;
}
EOT
        $op->{name}, $op->{convert}, $op->{operator}, $op->{convert};
}

_make_cond_jump( $_ ) foreach
  ( { name     => 'o_jump_if_i_lt',
      convert  => 'as_integer',
      operator => '<',
      },
    { name     => 'o_jump_if_i_le',
      convert  => 'as_integer',
      operator => '<=',
      },
    { name     => 'o_jump_if_i_eq',
      convert  => 'as_integer',
      operator => '==',
      },
    { name     => 'o_jump_if_i_ge',
      convert  => 'as_integer',
      operator => '>=',
      },
    { name     => 'o_jump_if_i_gt',
      convert  => 'as_integer',
      operator => '>',
      },

    { name     => 'o_jump_if_f_lt',
      convert  => 'as_float',
      operator => '<',
      },
    { name     => 'o_jump_if_f_le',
      convert  => 'as_float',
      operator => '<=',
      },
    { name     => 'o_jump_if_f_eq',
      convert  => 'as_float',
      operator => '==',
      },
    { name     => 'o_jump_if_f_ge',
      convert  => 'as_float',
      operator => '>=',
      },
    { name     => 'o_jump_if_f_gt',
      convert  => 'as_float',
      operator => '>',
      },

    { name     => 'o_jump_if_s_eq',
      convert  => 'as_string',
      operator => 'eq',
      },
    { name     => 'o_jump_if_s_ne',
      convert  => 'as_string',
      operator => 'ne',
      },
    );

sub _make_compare {
    my( $op ) = @_;

    my $ret = $op->{new_type} eq 'int' ?
                  '$r' :
                  'Language::P::Toy::Value::StringNumber->new( $runtime, { integer => $r } )';

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};
    my $r = $vl->%s( $runtime ) %s $vr->%s( $runtime ) ? 1 : 0;

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

sub _make_unary {
    my( $op ) = @_;

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber
                                    ->new( $runtime, { %s => %s } );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{type}, $op->{expression};
    die $@ if $@;
}

_make_unary( $_ ) foreach
  ( { name       => 'o_negate',
      type       => 'float',
      expression => '-$v->as_float( $runtime )',
      },
    { name       => 'o_stringify',
      type       => 'string',
      expression => '$v->as_string( $runtime )',
      },
    { name       => 'o_abs',
      type       => 'float',
      expression => 'abs $v->as_float( $runtime )',
      },
    { name       => 'o_chr',
      type       => 'string',
      expression => 'chr $v->as_integer( $runtime )',
      },
    { name       => 'o_bit_not',
      type       => 'int',
      expression => '~ $v->as_integer( $runtime )',
      },
    );

sub _make_boolean_unary {
    my( $op ) = @_;

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Scalar
                                    ->new_boolean( $runtime, %s );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{expression};
    die $@ if $@;
}

_make_boolean_unary( $_ ) foreach
  ( { name       => 'o_not',
      expression => '!$v->as_boolean_int( $runtime )',
      },
    { name       => 'o_chdir',
      expression => 'chdir $v->as_string( $runtime )',
      },
    { name       => 'o_defined',
      expression => '$v->is_defined( $runtime )',
      },
    );

sub o_exists {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_boolean( $runtime,
                                                       $v->is_subroutine );

    return $pc + 1;
}

sub o_preinc {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $v->pre_increment( $runtime );

    return $pc + 1;
}

sub o_postinc {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $v->post_increment( $runtime );

    return $pc + 1;
}

sub o_predec {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $v->pre_decrement( $runtime );

    return $pc + 1;
}

sub o_postdec {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $v->post_decrement( $runtime );

    return $pc + 1;
}

sub o_assign {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = $runtime->{_stack}[-1];

    $vl->assign( $runtime, $vr );

    return $pc + 1;
}

sub o_glob_slot_create {
    my( $op, $runtime, $pc ) = @_;
    my $glob = pop @{$runtime->{_stack}};
    my $slot = $op->{slot};

    push @{$runtime->{_stack}}, $glob->get_or_create_slot( $runtime, $slot );

    return $pc + 1;
}

sub o_glob_slot {
    my( $op, $runtime, $pc ) = @_;
    my $glob = pop @{$runtime->{_stack}};
    my $slot = $op->{slot};

    push @{$runtime->{_stack}}, $glob->get_slot( $runtime, $slot );

    return $pc + 1;
}

sub o_glob_slot_set {
    my( $op, $runtime, $pc ) = @_;

    my $value = pop @{$runtime->{_stack}};
    my $glob = pop @{$runtime->{_stack}};
    my $slot = $op->{slot};

    $glob->set_slot( $runtime, $slot, $value );

    return $pc + 1;
}

sub o_unlink {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my @args;

    for( my $it = $args->iterator( $runtime ); $it->next( $runtime ); ) {
        my $arg = $it->item( $runtime );

        push @args, $arg->as_string( $runtime );
    }

    my $ret = unlink @args;

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber
                                    ->new( $runtime, { integer => $ret } );
    return $pc + 1;
}

sub o_rmdir {
    my( $op, $runtime, $pc ) = @_;
    my $arg = pop @{$runtime->{_stack}};
    my $ret = rmdir $arg->as_string( $runtime );

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Scalar
                                    ->new_boolean( $runtime, $ret );

    return $pc + 1;
}

sub o_binmode {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my $handle = $args->get_item( $runtime, 0 );
    my $layer = $args->get_count( $runtime ) == 2 ? $args->get_item( $runtime, 1 )->as_string( $runtime ) : ':raw';

    push @{$runtime->{_stack}}, $handle->set_layer( $runtime, $layer );

    return $pc + 1;
}

sub o_open {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};

    my( $ret, $fh );
    if( $args->get_count( $runtime ) == 2 ) {
        $ret = open $fh, $args->get_item( $runtime, 1 )->as_string( $runtime );
    } elsif( $args->get_count( $runtime ) == 3 ) {
        $ret = open $fh, $args->get_item( $runtime, 1 )->as_string( $runtime ),
                         $args->get_item( $runtime, 2 )->as_string( $runtime );
    } else {
        die "Only 2/3-arg open supported";
    }
    my $dest = $args->get_item( $runtime, 0 );
    my $pfh = Language::P::Toy::Value::Handle->new( $runtime, { handle => $fh } );
    $dest->set_slot( $runtime, 'io', $pfh );

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Scalar
                                    ->new_boolean( $runtime, $ret );
    return $pc + 1;
}

sub o_close {
    my( $op, $runtime, $pc ) = @_;
    my $handle = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $handle->close( $runtime );

    return $pc + 1;
}

sub o_die {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my $info = $runtime->current_frame_info;

    my $message = '';
    for( my $iter = $args->iterator( $runtime ); $iter->next( $runtime ); ) {
        $message .= $iter->item->as_string;
    }

    Language::P::Toy::Exception->throw
        ( message  => $message,
          position => [ $info->{file}, $info->{line} ],
          );
}

sub o_backtick {
    my( $op, $runtime, $pc ) = @_;
    my $arg = pop @{$runtime->{_stack}};
    my $command = $arg->as_string( $runtime );

    # FIXME context
    my $ret = `$command`;

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( $runtime, { string => $ret } );

    return $pc + 1;
}

sub _make_bool_ft {
    my( $op ) = @_;

    eval sprintf <<'EOT',
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $file = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Scalar
                                    ->new_boolean( $runtime, -%s( $file->as_string( $runtime ) ) );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{operator};
    die $@ if $@;
}

_make_bool_ft( $_ ) foreach
  ( { name     => 'o_ft_isdir',
      operator => 'd',
      },
    { name     => 'o_ft_ischarspecial',
      operator => 'c',
      },
    );

sub o_array_element {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};
    my $index = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $array->get_item_or_undef( $runtime, $index->as_integer( $runtime ) );

    return $pc + 1;
}

sub o_exists_array {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};
    my $index = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $array->exists( $runtime, $index->as_integer( $runtime ) );

    return $pc + 1;
}

sub o_hash_element {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $key = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $hash->get_item_or_undef( $runtime, $key->as_string( $runtime ) );

    return $pc + 1;
}

sub o_exists_hash {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $key = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $hash->exists( $runtime, $key->as_string( $runtime ) );

    return $pc + 1;
}

sub o_array_size {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( $runtime, { integer => $array->get_count( $runtime ) - 1 } );

    return $pc + 1;
}

sub o_array_push {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my $arr = pop @{$runtime->{_stack}};
    my $v = $arr->push_list( $runtime, $args );

    push @{$runtime->{_stack}}, $v;

    return $pc + 1;
}

sub o_array_pop {
    my( $op, $runtime, $pc ) = @_;
    my $arr = pop @{$runtime->{_stack}};
    my $v = $arr->pop_value( $runtime );

    push @{$runtime->{_stack}}, $v;

    return $pc + 1;
}

sub o_array_unshift {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my $arr = pop @{$runtime->{_stack}};
    my $v = $arr->unshift_list( $runtime, $args );

    push @{$runtime->{_stack}}, $v;

    return $pc + 1;
}

sub o_array_shift {
    my( $op, $runtime, $pc ) = @_;
    my $arr = pop @{$runtime->{_stack}};
    my $v = $arr->shift_value( $runtime );

    push @{$runtime->{_stack}}, $v;

    return $pc + 1;
}

sub o_reference {
    my( $op, $runtime, $pc ) = @_;
    my $value = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Reference->new( $runtime, { reference => $value } );

    return $pc + 1;
}

sub o_anonymous_array {
    my( $op, $runtime, $pc ) = @_;
    my $list = pop @{$runtime->{_stack}};
    my $array = Language::P::Toy::Value::Array->new( $runtime );

    $array->assign( $runtime, $list );

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Reference->new( $runtime, { reference => $array } );

    return $pc + 1;
}

sub o_anonymous_hash {
    my( $op, $runtime, $pc ) = @_;
    my $list = pop @{$runtime->{_stack}};
    my $hash = Language::P::Toy::Value::Hash->new( $runtime );

    $hash->assign( $runtime, $list );

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Reference->new( $runtime, { reference => $hash } );

    return $pc + 1;
}

sub o_reftype {
    my( $op, $runtime, $pc ) = @_;
    my $value = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $value->reference_type( $runtime );

    return $pc + 1;
}

sub o_bless {
    my( $op, $runtime, $pc ) = @_;
    my $name = pop @{$runtime->{_stack}};
    my $stash = $runtime->symbol_table->get_package( $runtime, $name->as_string( $runtime ), 1 );
    my $ref = pop @{$runtime->{_stack}};

    $ref->bless( $runtime, $stash );
    push @{$runtime->{_stack}}, $ref;

    return $pc + 1;
}

sub o_dereference_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $ref = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $ref->dereference_scalar( $runtime );

    return $pc + 1;
}

sub o_vivify_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $ref = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $ref->vivify_scalar( $runtime );

    return $pc + 1;
}

sub o_dereference_array {
    my( $op, $runtime, $pc ) = @_;
    my $ref = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $ref->dereference_array( $runtime );

    return $pc + 1;
}

sub o_vivify_array {
    my( $op, $runtime, $pc ) = @_;
    my $ref = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $ref->vivify_array( $runtime );

    return $pc + 1;
}

sub o_dereference_hash {
    my( $op, $runtime, $pc ) = @_;
    my $ref = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $ref->dereference_hash( $runtime );

    return $pc + 1;
}

sub o_vivify_hash {
    my( $op, $runtime, $pc ) = @_;
    my $ref = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $ref->vivify_hash( $runtime );

    return $pc + 1;
}

sub o_dereference_glob {
    my( $op, $runtime, $pc ) = @_;
    my $ref = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $ref->dereference_glob( $runtime );

    return $pc + 1;
}

sub o_dereference_subroutine {
    my( $op, $runtime, $pc ) = @_;
    my $ref = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $ref->dereference_subroutine( $runtime );

    return $pc + 1;
}

sub o_make_closure {
    my( $op, $runtime, $pc ) = @_;
    my $sub = pop @{$runtime->{_stack}};
    my $clone = Language::P::Toy::Value::Subroutine->new
                    ( $runtime,
                      { bytecode   => $sub->bytecode,
                        stack_size => $sub->stack_size,
                        lexicals   => $sub->lexicals ? $sub->lexicals->new_scope( $runtime ) : undef,
                        closed     => $sub->closed,
                        } );
    $runtime->make_closure( $clone );

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Reference->new
                                    ( $runtime,
                                      { reference => $clone,
                                        } );

    return $pc + 1;
}

sub o_localize_glob_slot {
    my( $op, $runtime, $pc ) = @_;
    my $glob = $runtime->symbol_table->get_symbol( $runtime, $op->{name}, '*', 1 );
    my $to_save = $glob->get_slot( $runtime, $op->{slot} );
    my $saved = $to_save->localize( $runtime );

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = $to_save;
    $glob->set_slot( $runtime, $op->{slot}, $saved );
    push @{$runtime->{_stack}}, $saved;

    return $pc + 1;
}

sub o_restore_glob_slot {
    my( $op, $runtime, $pc ) = @_;
    my $glob = $runtime->symbol_table->get_symbol( $runtime, $op->{name}, '*', 1 );
    my $saved = $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}];

    $glob->set_slot( $runtime, $op->{slot}, $saved ) if $saved;
    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = undef;

    return $pc + 1;
}

sub o_iterator {
    my( $op, $runtime, $pc ) = @_;
    my $list = pop @{$runtime->{_stack}};
    my $iter = $list->iterator( $runtime );

    push @{$runtime->{_stack}}, $iter;

    return $pc + 1;
}

sub o_iterator_next {
    my( $op, $runtime, $pc ) = @_;
    my $iter = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $iter->next( $runtime ) ? $iter->item( $runtime ) : undef;

    return $pc + 1;
}

sub o_do_file {
    my( $op, $runtime, $pc ) = @_;
    my $file = pop @{$runtime->{_stack}};
    my $file_str = $file->as_string( $runtime );
    my $real_path = $runtime->search_file( $file_str );
    my $real_path_str = $real_path->as_string( $runtime );

    $runtime->run_file( $real_path_str, 0, _context( $op, $runtime ) );

    my $inc = $runtime->symbol_table->get_symbol( $runtime, 'INC', '%', 1 );
    $inc->set_item( $runtime, $file_str, $real_path );

    return $pc + 1;
}

sub o_require_file {
    my( $op, $runtime, $pc ) = @_;
    my $file = pop @{$runtime->{_stack}};
    my $file_str = $file->as_string( $runtime );
    my $inc = $runtime->symbol_table->get_symbol( $runtime, 'INC', '%', 1 );

    if( $inc->has_item( $runtime, $file_str ) ) {
        push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new
                                        ( $runtime, { integer => 1 } );

        return $pc + 1;
    }

    my $real_path = $runtime->search_file( $file_str );
    my $real_path_str = $real_path->as_string( $runtime );

    $runtime->run_file( $real_path_str, 0, _context( $op, $runtime ) );

    # FIXME check return value

    $inc->set_item( $runtime, $file_str, $real_path );

    return $pc + 1;
}

sub o_eval {
    my( $op, $runtime, $pc ) = @_;
    my $string = pop @{$runtime->{_stack}};
    # lexicals for parsing
    my $parse_lex = Language::P::Parser::Lexicals->new( $runtime );
    foreach my $k ( keys %{$op->{lexicals}} ) {
        my( $sigil, $name ) = split /\0/, $k;
        $parse_lex->add_name( $sigil, $name );
    }
    foreach my $k ( keys %{$op->{globals}} ) {
        my( $sigil, $name ) = split /\0/, $k;
        $parse_lex->add_name_our( $sigil, $name, $op->{globals}{$k} );
    }

    $runtime->eval_string( $string->as_string( $runtime ),
                           _context( $op, $runtime ),
                           { lexicals => $parse_lex,
                             hints    => $op->{hints},
                             warnings => $op->{warnings},
                             package  => $op->{package},
                             },
                           [ $op->{lexicals}, $runtime->{_code}, $parse_lex ] );

    return $pc + 1;
}

sub o_eval_regex {
    my( $op, $runtime, $pc ) = @_;
    my $string = pop @{$runtime->{_stack}};

    my $re = $runtime->compile_regex( $string->as_string( $runtime ) );
    push @{$runtime->{_stack}}, $re;

    return $pc + 1;
}

1;
