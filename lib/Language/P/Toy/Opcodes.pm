package Language::P::Toy::Opcodes;

use strict;
use warnings;
use Exporter 'import';

use Scalar::Util; # dualvar

use Language::P::Toy::Value::StringNumber;
use Language::P::Toy::Value::Reference;
use Language::P::Toy::Value::Array;
use Language::P::Toy::Value::List;
use Language::P::Toy::Value::LvalueList;
use Language::P::Toy::Value::Pos;
use Language::P::Toy::Value::Vec;
use Language::P::Toy::Value::Range;
use Language::P::Toy::Value::Substr;
use Language::P::Toy::Exception;
use Language::P::Constants qw(:all);

use Language::P::Toy::Opcodes::Regex qw(:opcodes);

our @EXPORT_OK = qw(o);

sub o {
    my( $name, %args ) = @_;

    Carp::confess( "Invalid opcode '$name'" )
        unless defined $Language::P::Toy::Opcodes::{"o_$name"};
    my $fun = *{$Language::P::Toy::Opcodes::{"o_$name"}}{CODE};
    Carp::confess( "Invalid opcode '$name'" )
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

my $empty_list = Language::P::Toy::Value::List->new( undef );

sub _return_value {
    my( $runtime, $cxt, $rv ) = @_;

    if( $cxt == CXT_SCALAR ) {
        if( $rv->get_count( $runtime ) > 0 ) {
            return $rv->get_item( $runtime, $rv->get_count( $runtime ) - 1 )
                      ->as_scalar( $runtime );
        } else {
            return Language::P::Toy::Value::Undef->new( $runtime );
        }
    } elsif( $cxt == CXT_LIST ) {
        return $rv;
    } elsif( $cxt == CXT_VOID ) {
        # it is easier to generate code if a subroutine
        # always returns a value (even if a dummy one)
        return $empty_list;
    }
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

sub o_discard_stack {
    my( $op, $runtime, $pc ) = @_;

    $#{$runtime->{_stack}} = $runtime->{_frame};

    return $pc + 1;
}

sub o_pop {
    my( $op, $runtime, $pc ) = @_;

    pop @{$runtime->{_stack}};

    return $pc + 1;
}

sub o_join {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my $str = $args->get_item( $runtime, 0 )->as_string( $runtime );
    my $res = '';
    my $first = 1;

    for( my $iter = $args->iterator_from( $runtime, 1 ); $iter->next( $runtime ); ) {
        $res .= $str unless $first;
        $first = 0;
        $res .= $iter->item( $runtime )->as_string( $runtime );
    }

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_string( $runtime, $res );

    return $pc + 1;
}

sub o_sort {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};

    # cheat
    my @strings = map $_->as_string( $runtime ), @{$args->array};
    my @res = map Language::P::Toy::Value::Scalar->new_string( $runtime, $_ ),
                  sort @strings;
    my $res = Language::P::Toy::Value::List->new
                  ( $runtime, { array => \@res } );

    push @{$runtime->{_stack}}, $res;

    return $pc + 1;
}

sub o_print {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my $arg_fh = pop @{$runtime->{_stack}};
    my $fh = $arg_fh->as_handle( $runtime );

    for( my $iter = $args->iterator( $runtime ); $iter->next( $runtime ); ) {
        $fh->write( $runtime, $iter->item( $runtime ) );
    }

    # HACK
    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 1 } );

    return $pc + 1;
}

sub o_sprintf {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my $format = $args->get_item( $runtime, 0 )->as_string( $runtime );
    my @values;

    for( my $i = 1; $i < $args->get_count( $runtime ); ++$i ) {
        my $value = $args->get_item( $runtime, $i )->as_scalar( $runtime );
        push @values, Scalar::Util::dualvar( $value->as_float( $runtime ),
                                             $value->as_string( $runtime ) );
    }

    my $string = sprintf $format, @values;
    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_string( $runtime, $string );

    return $pc + 1;
}

sub o_readline {
    my( $op, $runtime, $pc ) = @_;
    my $arg_fh = pop @{$runtime->{_stack}};
    my $fh = $arg_fh->as_handle( $runtime );
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
#line 1 %s
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};
    my $r = $vl->%s( $runtime ) %s $vr->%s( $runtime );

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::StringNumber->new( $runtime, { %s => $r } );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{name},
        $op->{convert}, $op->{operator}, $op->{convert}, $op->{new_type};
    die $@ if $@;
}

sub _make_binary_op_assign {
    my( $op ) = @_;

    eval sprintf <<'EOT',
#line 1 %s
sub %s_assign {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = $runtime->{_stack}[-1];
    my $r = $vl->%s( $runtime ) %s $vr->%s( $runtime );

    $vl->set_%s( $runtime, $r );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{name},
        $op->{convert}, $op->{operator}, $op->{convert}, $op->{new_type};
    die $@ if $@;
}

# fixme integer arithmetic
_make_binary_op( $_ ), _make_binary_op_assign( $_ ) foreach
  ( { name     => '_add_default',
      convert  => 'as_integer',
      operator => '+',
      new_type => 'integer',
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
    { name     => '_shift_left_default',
      convert  => 'as_integer',
      operator => '<<',
      new_type => 'integer',
      },
    { name     => '_bit_or_default',
      convert  => 'as_integer',
      operator => '|',
      new_type => 'integer',
      },
    { name     => '_bit_or_string',
      convert  => 'as_string',
      operator => '|',
      new_type => 'string',
      },
    { name     => '_bit_and_default',
      convert  => 'as_integer',
      operator => '&',
      new_type => 'integer',
      },
    { name     => '_bit_and_string',
      convert  => 'as_string',
      operator => '&',
      new_type => 'string',
      },
    { name     => '_bit_xor_default',
      convert  => 'as_integer',
      operator => '^',
      new_type => 'integer',
      },
    { name     => '_bit_xor_string',
      convert  => 'as_string',
      operator => '^',
      new_type => 'string',
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

sub _make_bit_op {
    my( $name, $op ) = @_;

    eval sprintf <<'EOT',
#line 1 %s
sub _bit_%s_string_number {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};

    if( $vl->is_string && $vr->is_string ) {
        my $r = $vl->as_string( $runtime ) %s $vr->as_string( $runtime );

        push @{$runtime->{_stack}},
             Language::P::Toy::Value::StringNumber->new( $runtime,
                                                         { string => $r } );
    } else {
        my $r = $vl->as_integer( $runtime ) %s $vr->as_integer( $runtime );

        push @{$runtime->{_stack}},
             Language::P::Toy::Value::StringNumber->new( $runtime,
                                                         { integer => $r } );
    }

    return $pc + 1;
}

sub _bit_%s_assign_string_number {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = $runtime->{_stack}[-1];

    if( $vl->is_string && $vr->is_string ) {
        my $r = $vl->as_string( $runtime ) %s $vr->as_string( $runtime );

        $vl->set_string( $runtime, $r );
    } else {
        my $r = $vl->as_integer( $runtime ) %s $vr->as_integer( $runtime );

        $vl->set_integer( $runtime, $r );
    }

    return $pc + 1;
}
EOT
        $name, $name, $op, $op, $name, $op, $op;
}

_make_bit_op( 'or',  '|' );
_make_bit_op( 'and', '&' );
_make_bit_op( 'xor', '^' );

sub o_bit_not {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    if( $v->is_string( $runtime ) ) {
        push @{$runtime->{_stack}},
             Language::P::Toy::Value::Scalar->new_string
                 ( $runtime, ~$v->as_string( $runtime ) );
    } else {
        push @{$runtime->{_stack}},
             Language::P::Toy::Value::Scalar->new_integer
                 ( $runtime, ~$v->as_integer( $runtime ) );
    }

    return $pc + 1;
}

sub _do_add_string_number {
    my( $runtime, $vl, $vr ) = @_;

    if( $vl->is_float || $vr->is_float ) {
        my $r = $vl->as_float( $runtime ) + $vr->as_float( $runtime );

        push @{$runtime->{_stack}},
             Language::P::Toy::Value::StringNumber->new( $runtime,
                                                         { float => $r } );
    } else {
        my $r = $vl->as_integer( $runtime ) + $vr->as_integer( $runtime );

        # TODO detect overflow and promote to float
        push @{$runtime->{_stack}},
             Language::P::Toy::Value::StringNumber->new( $runtime,
                                                         { integer => $r } );
    }
}

sub _do_add_assign_string_number {
    my( $runtime, $vl, $vr ) = @_;

    if( $vl->is_float || $vr->is_float ) {
        my $r = $vl->as_float( $runtime ) + $vr->as_float( $runtime );

        $vl->set_float( $runtime, $r );
    } else {
        my $r = $vl->as_integer( $runtime ) + $vr->as_integer( $runtime );

        # TODO detect overflow and promote to float
        $vl->set_integer( $runtime, $r );
    }
}

sub _do_dispatch_overload {
    my( $runtime, $op, $vl, $vr, $reversed ) = @_;
    my $table = $vl->reference->overload_table;

    # TODO push all this down to an implementation detail and keep the
    #      interface generic
    # TODO implement the full overload semantics
    die "Missing operator '$op' for overloaded object"
      unless exists $table->{$op};
    my $rev = Language::P::Toy::Value::Scalar->new_boolean( $runtime, $reversed );
    my $args = Language::P::Toy::Value::List->new
                   ( $runtime,
                     { array => [ $vl, $vr, $rev ] } );
    # leaves the result on the stack, as expected by the caller
    $runtime->call_subroutine( $table->{$op}->reference, CXT_SCALAR, $args );
}

sub _add_string_number {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};

    _do_add_string_number( $runtime, $vl, $vr );

    return $pc + 1;
}

sub _add_maybe_overload {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};
    my $lo = $vl->is_overloaded;
    my $ro = $vr->is_overloaded;

    if( $lo || $ro ) {
        _do_dispatch_overload( $runtime, '+',
                               $lo ? $vl : $vr,
                               $lo ? $vr : $vl, !$lo );
    } else {
        _do_add_string_number( $runtime, $vl, $vr );
    }

    return $pc + 1;
}

sub _add_assign_string_number {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = $runtime->{_stack}[-1];

    _do_add_assign_string_number( $runtime, $vl, $vr );

    return $pc + 1;
}

sub _add_assign_maybe_overload {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = $runtime->{_stack}[-1];
    my $lo = $vl->is_overloaded;
    my $ro = $vr->is_overloaded;

    if( $lo || $ro ) {
        _do_dispatch_overload( $runtime, '+=',
                               $lo ? $vl : $vr,
                               $lo ? $vr : $vl, !$lo );
    } else {
        _do_add_assign_string_number( $runtime, $vl, $vr );
    }

    return $pc + 1;
}

my %dispatch_bit_or =
  ( -1  => { -1  => \&_bit_or_default,
              11 => \&_bit_or_string_number,
             },
     11 => { -1  => \&_bit_or_string_number,
             },
    );

my %dispatch_bit_and =
  ( -1  => { -1  => \&_bit_and_default,
              11 => \&_bit_and_string_number,
             },
     11 => { -1  => \&_bit_and_string_number,
             },
    );

my %dispatch_bit_xor =
  ( -1  => { -1  => \&_bit_xor_default,
              11 => \&_bit_xor_string_number,
             },
     11 => { -1  => \&_bit_xor_string_number,
             },
    );

my %dispatch_bit_or_assign =
  ( -1  => { -1  => \&_bit_or_assign_default,
              11 => \&_bit_or_assign_string_number,
             },
     11 => { -1  => \&_bit_or_assign_string_number,
             },
    );

my %dispatch_bit_and_assign =
  ( -1  => { -1  => \&_bit_and_assign_default,
              11 => \&_bit_and_assign_string_number,
             },
     11 => { -1  => \&_bit_and_assign_string_number,
             },
    );

my %dispatch_bit_xor_assign =
  ( -1  => { -1  => \&_bit_xor_assign_default,
              11 => \&_bit_xor_assign_string_number,
             },
     11 => { -1  => \&_bit_xor_assign_string_number,
             },
    );

my %dispatch_add =
  ( -1  => { -1  => \&_add_default,
              10 => \&_add_maybe_overload,
              11 => \&_add_string_number,
             },
     10 => { -1  => \&_add_maybe_overload,
             },
     11 => { -1  => \&_add_string_number,
              10 => \&_add_maybe_overload,
             },
    );

my %dispatch_add_assign =
  ( -1  => { -1  => \&_add_assign_default,
              10 => \&_add_assign_maybe_overload,
              11 => \&_add_assign_string_number,
             },
     10 => { -1  => \&_add_assign_maybe_overload,
             },
     11 => { -1  => \&_add_assign_string_number,
              10 => \&_add_assign_maybe_overload,
             },
    );

my %dispatch_shift_left =
  ( -1  => { -1  => \&_shift_left_default,
             },
     10 => { -1  => \&_shift_left_overload,
             },
    );

sub _dispatch {
    my( $table, $l, $r ) = @_;
    my $lt = $l->type;
    my $rt = $r->type;
    my $sub;

    return $sub
        if $sub = $table->{$lt}{$rt};
    return $table->{$lt}{$rt} = $sub
        if $sub = $table->{$lt}{-1};
    return $table->{$lt}{$rt} = $sub
        if $sub = $table->{-1}{$rt};
    return $table->{$lt}{$rt} = $sub
        if $sub = $table->{-1}{-1};
    die "Unable to dispatch types $lt, $rt";
}

sub o_bit_or {
    my( $op, $runtime, $pc ) = @_;
    my $vr = $runtime->{_stack}[-1];
    my $vl = $runtime->{_stack}[-2];

    return _dispatch( \%dispatch_bit_or, $vl, $vr )->( $op, $runtime, $pc );
}

sub o_bit_and {
    my( $op, $runtime, $pc ) = @_;
    my $vr = $runtime->{_stack}[-1];
    my $vl = $runtime->{_stack}[-2];

    return _dispatch( \%dispatch_bit_and, $vl, $vr )->( $op, $runtime, $pc );
}

sub o_bit_xor {
    my( $op, $runtime, $pc ) = @_;
    my $vr = $runtime->{_stack}[-1];
    my $vl = $runtime->{_stack}[-2];

    return _dispatch( \%dispatch_bit_xor, $vl, $vr )->( $op, $runtime, $pc );
}

sub o_bit_or_assign {
    my( $op, $runtime, $pc ) = @_;
    my $vr = $runtime->{_stack}[-1];
    my $vl = $runtime->{_stack}[-2];

    return _dispatch( \%dispatch_bit_or_assign, $vl, $vr )->( $op, $runtime, $pc );
}

sub o_bit_and_assign {
    my( $op, $runtime, $pc ) = @_;
    my $vr = $runtime->{_stack}[-1];
    my $vl = $runtime->{_stack}[-2];

    return _dispatch( \%dispatch_bit_and_assign, $vl, $vr )->( $op, $runtime, $pc );
}

sub o_bit_xor_assign {
    my( $op, $runtime, $pc ) = @_;
    my $vr = $runtime->{_stack}[-1];
    my $vl = $runtime->{_stack}[-2];

    return _dispatch( \%dispatch_bit_xor_assign, $vl, $vr )->( $op, $runtime, $pc );
}

sub o_add {
    my( $op, $runtime, $pc ) = @_;
    my $vr = $runtime->{_stack}[-1];
    my $vl = $runtime->{_stack}[-2];

    return _dispatch( \%dispatch_add, $vl, $vr )->( $op, $runtime, $pc );
}

sub o_add_assign {
    my( $op, $runtime, $pc ) = @_;
    my $vr = $runtime->{_stack}[-1];
    my $vl = $runtime->{_stack}[-2];

    return _dispatch( \%dispatch_add_assign, $vl, $vr )->( $op, $runtime, $pc );
}

sub o_repeat_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};

    my $res = $vl->as_string( $runtime ) x $vr->as_integer( $runtime );

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_string( $runtime, $res );

    return $pc + 1;
}

sub o_repeat_array {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};

    my @res = ( @{$vl->array} ) x $vr->as_integer( $runtime );

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::List->new( $runtime, { array => \@res } );

    return $pc + 1;
}

sub o_reverse {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my $cxt = _context( $op, $runtime );

    if( $cxt == CXT_LIST ) {
        my @res = reverse @{$args->array};

        push @{$runtime->{_stack}},
             Language::P::Toy::Value::List->new( $runtime, { array => \@res } );
    } else {
        my $value;

        if( $args->get_count == 0 ) {
            my $def = $runtime->symbol_table->get_symbol( $runtime, '_', '$' );

            $value = reverse $def->as_string( $runtime );
        } else {
            my $v = join "", map $_->as_string( $runtime ), @{$args->array};

            $value = reverse $v;
        }

        push @{$runtime->{_stack}},
             Language::P::Toy::Value::Scalar->new_string( $runtime, $value );
    }

    return $pc + 1;
}

sub o_shift_left {
    my( $op, $runtime, $pc ) = @_;
    my $vr = $runtime->{_stack}[-1];
    my $vl = $runtime->{_stack}[-2];

    return _dispatch( \%dispatch_shift_left, $vl, $vr )->( $op, $runtime, $pc );
}

sub o_push_element {
    my( $op, $runtime, $pc ) = @_;
    my $arg = pop @{$runtime->{_stack}};
    my $arr = pop @{$runtime->{_stack}};

    $arr->push_flatten( $runtime, $arg );

    return $pc + 1;
}

sub o_make_array {
    my( $op, $runtime, $pc ) = @_;
    my $st = $runtime->{_stack};

    # create the array
    my $array = Language::P::Toy::Value::Array->new( $runtime );
    if( $op->{count} ) {
        for( my $j = $#$st - $op->{count} + 1; $j <= $#$st; ++$j ) {
            $array->push_flatten( $runtime, $st->[$j] );
        }
        # clear the stack
        $#$st -= $op->{count} - 1;
        $st->[-1] = $array;
    } else {
        push @$st, $array;
    }

    return $pc + 1;
}

sub o_make_list {
    my( $op, $runtime, $pc ) = @_;
    my $st = $runtime->{_stack};

    # create the list
    my $list = ( $op->{context} & CXT_LVALUE ) ?
                   Language::P::Toy::Value::LvalueList->new( $runtime ) :
                   Language::P::Toy::Value::List->new( $runtime );
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

sub _want_value {
    my( $runtime, $cxt ) = @_;

    if( $cxt == CXT_VOID ) {
        return Language::P::Toy::Value::Undef->new( $runtime );
    } elsif( $cxt == CXT_SCALAR ) {
        return Language::P::Toy::Value::StringNumber->new( $runtime, { string => '' } );
    } elsif( $cxt == CXT_LIST ) {
        return Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 1 } );
    } else {
        die "Unknow context $cxt";
    }
}

sub o_want {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = _context( undef, $runtime );

    push @{$runtime->{_stack}}, _want_value( $runtime, $cxt );

    return $pc + 1;
}

sub o_caller {
    my( $op, $runtime, $pc ) = @_;
    my $level = $op->{arg_count} ?
                    pop( @{$runtime->{_stack}} )->as_integer( $runtime ) : 0;
    my $info = $runtime->frame_info_caller( $level );

    if( !$info ) {
        if( _context( $op, $runtime ) == CXT_SCALAR ) {
            push @{$runtime->{_stack}},
                 Language::P::Toy::Value::Undef->new( $runtime );
        } else {
            push @{$runtime->{_stack}}, $empty_list;
        }

        return $pc + 1;
    }

    my $package = Language::P::Toy::Value::Scalar->new_string
                      ( $runtime, $info->{package} );

    if( _context( $op, $runtime ) == CXT_LIST ) {
        my $file = Language::P::Toy::Value::Scalar->new_string
                       ( $runtime, $info->{file} );
        my $line = Language::P::Toy::Value::Scalar->new_integer
                       ( $runtime, $info->{line} );

        if( !$op->{arg_count} ) {
            push @{$runtime->{_stack}},
                 Language::P::Toy::Value::List->new
                     ( $runtime, { array => [ $package, $file, $line ] } );
        } else {
            my $subname = Language::P::Toy::Value::Scalar->new_string
                              ( $runtime, $info->{code_name} );
            my $hasargs = Language::P::Toy::Value::Undef->new( $runtime );
            my $want = _want_value( $runtime, $info->{context} );
            my $evaltext = Language::P::Toy::Value::Undef->new( $runtime );
            my $is_require = Language::P::Toy::Value::Undef->new( $runtime );
            my $warnings = Language::P::Toy::Value::Scalar->new_string
                               ( $runtime, $info->{warnings} );
            my $hints = Language::P::Toy::Value::Scalar->new_integer
                            ( $runtime, $info->{hints} );

            push @{$runtime->{_stack}},
                 Language::P::Toy::Value::List->new
                     ( $runtime,
                       { array => [ $package, $file, $line, $subname,
                                    $hasargs, $want, $evaltext,
                                    $is_require, $hints, $warnings ] } );
        }
    } else {
        push @{$runtime->{_stack}}, $package;
    }

    return $pc + 1;
}

sub o_dynamic_goto {
    my( $op, $runtime, $pc ) = @_;
    my $value = pop @{$runtime->{_stack}};

    if(    $value->isa( 'Language::P::Toy::Value::Reference' )
        && $value->reference->isa( 'Language::P::Toy::Value::Subroutine' ) ) {
        return $value->reference->tail_call( $runtime, $pc, _context( undef, $runtime ) );
    } else {
        die "Can't use goto with dynamic label yet";
    }
}

sub o_call {
    my( $op, $runtime, $pc ) = @_;
    my $sub = pop @{$runtime->{_stack}};

    return $sub->call( $runtime, $pc, _context( $op, $runtime ) );
}

sub o_call_method {
    my( $op, $runtime, $pc ) = @_;
    my $args = $runtime->{_stack}[-1];
    my $invocant = $args->get_item( $runtime, 0 );
    my $sub;

    if( ( my $idx = rindex $op->{method}, '::' ) >= 0 ) {
        my $pack = substr $op->{method}, 0, $idx;
        my $meth = substr $op->{method}, $idx + 2;

        my $stash = $runtime->symbol_table->get_package( $runtime, $pack, 1 );
        $sub = $stash->find_method( $runtime, $meth );
    } else {
        $sub = $invocant->find_method( $runtime, $op->{method} );
    }

    die "Can't find method $op->{method}" unless $sub;

    return $sub->call( $runtime, $pc, _context( $op, $runtime ) );
}

sub o_call_method_indirect {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};
    my $invocant = $args->get_item( $runtime, 0 );
    my $method = pop @{$runtime->{_stack}};

    # prepare the stack for the call
    push @{$runtime->{_stack}}, $args;

    my $sub;
    if(    $method->isa( 'Language::P::Toy::Value::Reference' )
        && $method->reference->isa( 'Language::P::Toy::Value::Subroutine' ) ) {
        $sub = $method->reference;
    } else {
        my $name = $method->as_string( $runtime );

        if( ( my $idx = rindex $name, '::' ) >= 0 ) {
            my $pack = substr $name, 0, $idx;
            my $meth = substr $name, $idx + 2;

            my $stash = $runtime->symbol_table->get_package( $runtime, $pack, 1 );
            $sub = $stash->find_method( $runtime, $meth );
        } else {
            $sub = $invocant->find_method( $runtime, $name );
        }

        die "Can't find method $name" unless $sub;
    }

    return $sub->call( $runtime, $pc, _context( $op, $runtime ) );
}

sub o_find_method {
    my( $op, $runtime, $pc ) = @_;
    my $invocant = pop @{$runtime->{_stack}};
    my $sub = $invocant->find_method( $runtime, $op->{method} );

    push @{$runtime->{_stack}}, $sub;

    return $pc + 1;
}

sub o_return {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = _context( undef, $runtime );
    my $rv = $runtime->{_stack}->[-1];
    my $rpc = $runtime->call_return;

    push @{$runtime->{_stack}}, _return_value( $runtime, $cxt, $rv );

    return $rpc + 1;
}

sub o_glob {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->symbol_table->get_symbol( $runtime, $op->{name}, '*',
                                                    $op->{create} );
    $value ||= Language::P::Toy::Value::Undef->new( $runtime );

    push @{$runtime->{_stack}}, $value;

    return $pc + 1;
}

sub o_stash {
    my( $op, $runtime, $pc ) = @_;
    my $value = $runtime->symbol_table->get_package( $runtime, $op->{name},
                                                     $op->{create} );
    $value ||= Language::P::Toy::Value::Undef->new( $runtime );

    push @{$runtime->{_stack}}, $value;

    return $pc + 1;
}

sub o_lexical_state_save {
    my( $op, $runtime, $pc ) = @_;

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] =
        { package  => $runtime->{_lex}{package},
          hints    => $runtime->{_lex}{hints},
          warnings => $runtime->{_lex}{warnings},
          };

    return $pc + 1;
}

sub o_lexical_state_restore {
    my( $op, $runtime, $pc ) = @_;

    $runtime->{_lex} = $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}];
    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = undef;

    return $pc + 1;
}

sub o_lexical_state_set {
    my( $op, $runtime, $pc ) = @_;

    $runtime->{_lex} =
        { package  => $op->{package},
          hints    => $op->{hints},
          warnings => $op->{warnings},
          };

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

sub o_localize_lexical {
    my( $op, $runtime, $pc ) = @_;

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] =
        $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{lexical}];

    return $pc + 1;
}

sub o_restore_lexical {
    my( $op, $runtime, $pc ) = @_;
    my $val = $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}];

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{lexical}] = $val if $val;
    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = undef;

    return $pc + 1;
}

sub o_lexical_pad {
    my( $op, $runtime, $pc ) = @_;
    my $pad = $runtime->{_stack}->[$runtime->{_frame} - 1];
    my $value = $pad->values->[$op->{index}]
                  ||= Language::P::Toy::Value::Undef->new( $runtime );

    push @{$runtime->{_stack}}, $value;

    return $pc + 1;
}

sub o_lexical_pad_set {
    my( $op, $runtime, $pc ) = @_;
    my $pad = $runtime->{_stack}->[$runtime->{_frame} - 1];
    my $value = pop @{$runtime->{_stack}};

    $pad->values->[$op->{index}] = $value;

    return $pc + 1;
}

sub o_lexical_pad_clear {
    my( $op, $runtime, $pc ) = @_;
    my $pad = $runtime->{_stack}->[$runtime->{_frame} - 1];

    $pad->values->[$op->{index}] = undef;

    return $pc + 1;
}

sub o_localize_lexical_pad {
    my( $op, $runtime, $pc ) = @_;
    my $pad = $runtime->{_stack}->[$runtime->{_frame} - 1];

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] =
        $pad->values->[$op->{lexical}];

    return $pc + 1;
}

sub o_restore_lexical_pad {
    my( $op, $runtime, $pc ) = @_;
    my $pad = $runtime->{_stack}->[$runtime->{_frame} - 1];
    my $val = $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}];

    $pad->values->[$op->{lexical}] = $val if $val;
    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = undef;

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
#line 1 %s
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};

    return $vl->%s( $runtime ) %s $vr->%s( $runtime ) ? $op->{to} : $pc + 1;
}
EOT
        $op->{name}, $op->{name},
        $op->{convert}, $op->{operator}, $op->{convert};
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
    { name     => 'o_jump_if_f_ne',
      convert  => 'as_float',
      operator => '!=',
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
#line 1 %s
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};
    my $r = $vl->%s( $runtime ) %s $vr->%s( $runtime ) ? 1 : 0;

    push @{$runtime->{_stack}}, %s;

    return $pc + 1;
}
EOT
        $op->{name}, $op->{name},
        $op->{convert}, $op->{operator}, $op->{convert}, $ret;
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
    { name     => 'o_compare_f_gt_scalar',
      convert  => 'as_float',
      operator => '>',
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
#line 1 %s
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber
                                    ->new( $runtime, { %s => %s } );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{name}, $op->{type}, $op->{expression};
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
    { name       => 'o_length',
      type       => 'integer',
      expression => '$v->get_length_int( $runtime )',
      },
    { name       => 'o_int',
      type       => 'integer',
      expression => '$v->as_integer( $runtime )',
      },
    );

sub _make_boolean_unary {
    my( $op ) = @_;

    eval sprintf <<'EOT',
#line 1 %s
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Scalar
                                    ->new_boolean( $runtime, %s );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{name}, $op->{expression};
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

sub o_scalar {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $v->as_scalar( $runtime );

    return $pc + 1;
}

sub o_undef {
    my( $op, $runtime, $pc ) = @_;
    my $val = pop @{$runtime->{_stack}};

    $val->undefine( $runtime );

    return $pc + 1;
}

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

sub o_quotemeta {
    my( $op, $runtime, $pc ) = @_;
    my $v = pop @{$runtime->{_stack}};
    my $r = $v->as_string( $runtime );

    $r =~ s{(\W)}{\\$1}g;

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_string( $runtime, $r );

    return $pc + 1;
}

sub o_assign {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};

    if(    $vl->isa( 'Language::P::Toy::Value::Array' )
        || $vl->isa( 'Language::P::Toy::Value::Hash' ) ) {
        my $count = $vl->assign_array( $runtime, $vr );

        if( _context( $op, $runtime ) == CXT_SCALAR ) {
            push @{$runtime->{_stack}},
                 Language::P::Toy::Value::Scalar->new_integer( $runtime, $count );
        } else {
            push @{$runtime->{_stack}}, $vl;
        }
    } else {
        $vl->assign( $runtime, $vr );

        push @{$runtime->{_stack}}, $vl;
    }

    return $pc + 1;
}

sub o_pos {
    my( $op, $runtime, $pc ) = @_;
    my $val = pop @{$runtime->{_stack}};
    my $sc = $val->as_scalar( $runtime );
    my $pos = Language::P::Toy::Value::Pos->new( $runtime, $sc );

    push @{$runtime->{_stack}}, $pos;

    return $pc + 1;
}

sub o_vec {
    my( $op, $runtime, $pc ) = @_;
    my $bits = pop @{$runtime->{_stack}};
    my $offset = pop @{$runtime->{_stack}};
    my $val = pop @{$runtime->{_stack}};

    my $vec = Language::P::Toy::Value::Vec->new
                  ( $runtime, $val->as_scalar( $runtime ),
                    $offset->as_integer( $runtime ),
                    $bits->as_integer( $runtime ),
                    );

    push @{$runtime->{_stack}}, $vec;

    return $pc + 1;
}

sub o_substr {
    my( $op, $runtime, $pc ) = @_;
    my $count = $op->{arg_count};
    my( $new_val, $length );
    $new_val = pop @{$runtime->{_stack}} if $count >= 4;
    $length = pop @{$runtime->{_stack}} if $count >= 3;
    my $offset = pop @{$runtime->{_stack}};
    my $val = pop @{$runtime->{_stack}};

    my $offset_int = $offset->as_integer( $runtime );
    my $value = $val->as_scalar( $runtime );
    my $value_length = $value->get_length_int;
    my $length_int;
    if( $count >= 3 ) {
        $length_int = $length->as_integer( $runtime );
    } else {
        $length_int = $value_length - $offset_int;
    }

    if( $count == 4 ) {
        my $str = $value->as_string( $runtime );
        my $sub = substr $str, $offset_int, $length_int,
                         $new_val->as_string( $runtime );

        $val->assign( $runtime, Language::P::Toy::Value::Scalar->new_string
                                    ( $runtime, $str ) );

        push @{$runtime->{_stack}},
             Language::P::Toy::Value::Scalar->new_string( $runtime, $sub );
    } else {
        my $substr = Language::P::Toy::Value::Substr->new
                         ( $runtime, $value, $offset_int, $length_int );

        push @{$runtime->{_stack}}, $substr;
    }

    return $pc + 1;
}

sub o_index {
    my( $op, $runtime, $pc ) = @_;
    my $argc = $op->{arg_count};
    my $start = 0;
    if( $argc == 3 ) {
        my $start_s = pop @{$runtime->{_stack}};

        $start = $start_s->as_integer( $runtime );
    }
    my $substr = pop @{$runtime->{_stack}};
    my $str = pop @{$runtime->{_stack}};

    my $pos = index $str->as_string( $runtime ),
                    $substr->as_string( $runtime ),
                    $start;

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_integer( $runtime, $pos );

    return $pc + 1;
}

sub o_ord {
    my( $op, $runtime, $pc ) = @_;
    my $scalar = pop @{$runtime->{_stack}};
    my $str = $scalar->as_string( $runtime );

    my $int = ord substr $str, 0, 1;

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_integer( $runtime, $int );

    return $pc + 1;
}

sub o_oct {
    my( $op, $runtime, $pc ) = @_;
    my $scalar = pop @{$runtime->{_stack}};
    my $int = oct $scalar->as_string( $runtime );

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_integer( $runtime, $int );

    return $pc + 1;
}

sub o_uc {
    my( $op, $runtime, $pc ) = @_;
    my $scalar = pop @{$runtime->{_stack}};
    my $str = uc $scalar->as_string( $runtime );

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_string( $runtime, $str );

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
    my $handle = $args->get_item( $runtime, 0 )->as_handle( $runtime );
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
    $dest->set_handle( $runtime, $pfh );

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Scalar
                                    ->new_boolean( $runtime, $ret );
    return $pc + 1;
}

sub o_close {
    my( $op, $runtime, $pc ) = @_;
    my $handle = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}},
         $handle->as_handle( $runtime )->close( $runtime );

    return $pc + 1;
}

sub o_die {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};

    if( $args->get_count == 1 && $args->get_item( $runtime, 0 )->type == 10 ) {
        my $exc = Language::P::Toy::Exception->new
                      ( { object  => $args->get_item( $runtime, 0 ),
                          } );

        return $runtime->throw_exception( $exc, 1 );
    }

    my $message = '';
    if( $args->get_count == 0 ) {
        my $exc = $runtime->symbol_table->get_symbol( $runtime, '@', '$', 1 );

        if( $exc->is_defined( $runtime ) ) {
            $message .= $exc->as_string( $runtime ) . "\t...propagated";
        } else {
            $message = 'Died';
        }
    } else {
        for( my $iter = $args->iterator( $runtime ); $iter->next( $runtime ); ) {
            $message .= $iter->item->as_string;
        }
    }

    my $exc = Language::P::Toy::Exception->new
                  ( { message  => $message,
                      } );

    return $runtime->throw_exception( $exc, 1 );
}

sub o_warn {
    my( $op, $runtime, $pc ) = @_;
    my $args = pop @{$runtime->{_stack}};

    # TODO handle empty argument list when $@ is set and when it is not

    my $message = '';
    for( my $iter = $args->iterator( $runtime ); $iter->next( $runtime ); ) {
        $message .= $iter->item->as_string;
    }

    if( length $message and substr( $message, -1 ) ne "\n" ) {
        my $info = $runtime->current_frame_info;

        $message .= " at $info->{file} line $info->{line}.\n";
    }

    my $stderr = $runtime->symbol_table->get_symbol( $runtime, 'STDERR', 'I' );

    $stderr->write_string( $runtime, $message );

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_integer( $runtime, 1 );

    return $pc + 1;
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
#line 1 %s
sub %s {
    my( $op, $runtime, $pc ) = @_;
    my $file = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Scalar
                                    ->new_boolean( $runtime, -%s( $file->as_string( $runtime ) ) );

    return $pc + 1;
}
EOT
        $op->{name}, $op->{name}, $op->{operator};
    die $@ if $@;
}

_make_bool_ft( $_ ) foreach
  ( { name     => 'o_ft_isdir',
      operator => 'd',
      },
    { name     => 'o_ft_ischarspecial',
      operator => 'c',
      },
    { name     => 'o_ft_isfile',
      operator => 'f',
      },
    );

sub o_array_element {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};
    my $index = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $array->get_item_or_undef( $runtime, $index->as_integer( $runtime ), $op->{create} );

    return $pc + 1;
}

sub o_array_slice {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = _context( $op, $runtime );
    my $array = pop @{$runtime->{_stack}};
    my $indices = pop @{$runtime->{_stack}};
    my $rv = $array->slice( $runtime, $indices, $op->{create} );

    push @{$runtime->{_stack}}, _return_value( $runtime, $cxt, $rv );

    return $pc + 1;
}

sub o_list_slice {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = _context( $op, $runtime );
    my $list = pop @{$runtime->{_stack}};
    my $indices = pop @{$runtime->{_stack}};
    my $rv = $list->slice( $runtime, $indices );

    push @{$runtime->{_stack}}, _return_value( $runtime, $cxt, $rv );

    return $pc + 1;
}

sub o_splice {
    my( $op, $runtime, $pc ) = @_;
    my $count = $op->{arg_count};
    my @values;

    @values = splice @{$runtime->{_stack}}, -( $count - 3 ) if $count >= 4;
    my( $offset, $length );
    $length = pop @{$runtime->{_stack}} if $count >= 3;
    $offset = pop @{$runtime->{_stack}} if $count >= 2;
    my $arr = pop @{$runtime->{_stack}};

    my $arr_length = $arr->get_count( $runtime );
    my( $length_int, $offset_int );
    if( $count >= 2 ) {
        $offset_int = $offset->as_integer( $runtime );
    } else {
        $offset_int = 0;
    }
    if( $count >= 3 ) {
        $length_int = $length->as_integer( $runtime );
    } else {
        $length_int = $arr_length - $offset_int;
    }

    my @res;
    if( $count >= 4 ) {
        @res = splice @{$arr->array}, $offset_int, $length_int, @values;
    } else {
        @res = splice @{$arr->array}, $offset_int, $length_int;
    }

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::List->new( $runtime, { array => \@res } );

    return $pc + 1;
}

sub o_exists_array {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};
    my $index = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $array->exists( $runtime, $index->as_integer( $runtime ) );

    return $pc + 1;
}

sub o_delete_array {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};
    my $index = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}},
         $array->delete_item( $runtime, $index->as_integer( $runtime ) );

    return $pc + 1;
}

sub o_delete_array_slice {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};
    my $indices = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}},
         $array->delete_slice( $runtime, $indices );

    return $pc + 1;
}

sub o_hash_element {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $key = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $hash->get_item_or_undef( $runtime, $key->as_string( $runtime ), $op->{create} );

    return $pc + 1;
}

sub o_hash_slice {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = _context( $op, $runtime );
    my $hash = pop @{$runtime->{_stack}};
    my $keys = pop @{$runtime->{_stack}};
    my $rv = $hash->slice( $runtime, $keys, $op->{create} );

    push @{$runtime->{_stack}}, _return_value( $runtime, $cxt, $rv );

    return $pc + 1;
}

sub o_exists_hash {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $key = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $hash->exists( $runtime, $key->as_string( $runtime ) );

    return $pc + 1;
}

sub o_delete_hash {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $index = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}},
         $hash->delete_item( $runtime, $index->as_string( $runtime ) );

    return $pc + 1;
}

sub o_delete_hash_slice {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $indices = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}},
         $hash->delete_slice( $runtime, $indices );

    return $pc + 1;
}

sub o_keys {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $res = Language::P::Toy::Value::List->new( $runtime );

    $res->assign_iterator( $runtime, $hash->key_iterator( $runtime ) );
    push @{$runtime->{_stack}}, $res;

    return $pc + 1;
}

sub o_values {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $res = Language::P::Toy::Value::List->new( $runtime );

    $res->assign_iterator( $runtime, $hash->value_iterator( $runtime ) );
    push @{$runtime->{_stack}}, $res;

    return $pc + 1;
}

sub o_each {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $key_scalar = $hash->next_key( $runtime );
    my $cxt = _context( $op, $runtime );

    if( defined $key_scalar ) {
        my $key = $key_scalar->as_string( $runtime );
        if( $cxt == CXT_SCALAR ) {
            push @{$runtime->{_stack}}, $key_scalar;
        } else {
            my $value = $hash->get_item_or_undef( $runtime, $key );
            push @{$runtime->{_stack}},
                 Language::P::Toy::Value::List->new( $runtime,
                                                     { array => [ $key_scalar,
                                                                  $value ] } );
        }
    } else {
        if( $cxt == CXT_SCALAR ) {
            push @{$runtime->{_stack}},
                 Language::P::Toy::Value::Undef->new( $runtime );
        } else {
            push @{$runtime->{_stack}}, $empty_list;
        }
    }

    return $pc + 1;
}

sub o_glob_element {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $key = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}}, $hash->get_item_or_undef( $runtime, $key->as_string( $runtime ) );

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

sub o_range {
    my( $op, $runtime, $pc ) = @_;
    my $vr = pop @{$runtime->{_stack}};
    my $vl = pop @{$runtime->{_stack}};

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Range->new
             ( $runtime, { start => $vl, end => $vr } );

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

    push @{$runtime->{_stack}}, $ref->dereference_scalar( $runtime, $op->{create} );

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

    push @{$runtime->{_stack}}, $ref->dereference_array( $runtime, $op->{create} );

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

    push @{$runtime->{_stack}}, $ref->dereference_hash( $runtime, $op->{create} );

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

    push @{$runtime->{_stack}}, $ref->dereference_glob( $runtime, $op->{create} );

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
                        prototype  => $sub->prototype,
                        } );
    $runtime->make_closure( $clone );

    push @{$runtime->{_stack}}, Language::P::Toy::Value::Reference->new
                                    ( $runtime,
                                      { reference => $clone,
                                        } );

    return $pc + 1;
}

sub o_make_qr {
    my( $op, $runtime, $pc ) = @_;
    my $pattern = pop @{$runtime->{_stack}};
    my $stash = $runtime->symbol_table->get_package( $runtime, 'Regexp', 1 );
    my $ref = Language::P::Toy::Value::Reference->new
                  ( $runtime, { reference => $pattern } );

    $ref->bless( $runtime, $stash );
    push @{$runtime->{_stack}}, $ref;

    return $pc + 1;
}

sub o_localize_array_element {
    my( $op, $runtime, $pc ) = @_;
    my $array = pop @{$runtime->{_stack}};
    my $index = pop @{$runtime->{_stack}};
    my $int_index = $index->as_integer( $runtime );

    my $saved = $array->localize_element( $runtime, $int_index );
    my $new = $array->get_item_or_undef( $runtime, $int_index );

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] =
        [ $array, $int_index, $saved ];

    push @{$runtime->{_stack}}, $new;

    return $pc + 1;
}

sub o_restore_array_element {
    my( $op, $runtime, $pc ) = @_;
    my $saved = $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}];

    $saved->[0]->restore_item( $runtime, $saved->[1], $saved->[2] ) if $saved;
    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = undef;

    return $pc + 1;
}

sub o_localize_hash_element {
    my( $op, $runtime, $pc ) = @_;
    my $hash = pop @{$runtime->{_stack}};
    my $index = pop @{$runtime->{_stack}};
    my $str_key = $index->as_string( $runtime );

    my $saved = $hash->localize_element( $runtime, $str_key );
    my $new = $hash->get_item_or_undef( $runtime, $str_key );

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] =
        [ $hash, $str_key, $saved ];

    push @{$runtime->{_stack}}, $new;

    return $pc + 1;
}

sub o_restore_hash_element {
    my( $op, $runtime, $pc ) = @_;
    my $saved = $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}];

    # an undef values deletes the key
    $saved->[0]->restore_item( $runtime, $saved->[1], $saved->[2] ) if $saved;
    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = undef;

    return $pc + 1;
}

sub o_localize_glob_slot {
    my( $op, $runtime, $pc ) = @_;
    my $glob = $runtime->symbol_table->get_symbol( $runtime, $op->{name}, '*', 1 );
    my $to_save = $glob->get_or_create_slot( $runtime, $op->{slot} );
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

    my $ok = eval {
        $runtime->run_file( $real_path_str, 0, _context( $op, $runtime ) );
        1;
    };
    $runtime->throw_exception( $@ ) unless $ok;

    my $inc = $runtime->symbol_table->get_symbol( $runtime, 'INC', '%', 1 );
    $inc->set_item( $runtime, $file_str, $real_path );

    return $pc + 1;
}

sub o_require_file {
    my( $op, $runtime, $pc ) = @_;
    my $file = pop @{$runtime->{_stack}};

    if( $file->is_integer( $runtime ) || $file->is_float( $runtime ) ) {
        my $value = $file->as_float( $runtime );
        my $version = $runtime->symbol_table->get_symbol( $runtime, ']', '$' );
        my $v = $version->as_float( $runtime );

        if( $v >= $value ) {
            push @{$runtime->{_stack}},
                 Language::P::Toy::Value::Scalar->new_integer( $runtime, 1 );
            return $pc + 1;
        }

        my $msg = sprintf 'Perl %f required--this is only %f stopped.',
                          $value, $v;
        my $exc = Language::P::Toy::Exception->new
                      ( { message  => $msg,
                          } );

        return $runtime->throw_exception( $exc, 1 );
    }

    my $file_str = $file->as_string( $runtime );
    my $inc = $runtime->symbol_table->get_symbol( $runtime, 'INC', '%', 1 );

    if( $inc->has_item( $runtime, $file_str ) ) {
        push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new
                                        ( $runtime, { integer => 1 } );

        return $pc + 1;
    }

    my $real_path = $runtime->search_file( $file_str );
    my $real_path_str = $real_path->as_string( $runtime );

    my $ok = eval {
        $runtime->run_file( $real_path_str, 0, _context( $op, $runtime ) );
        1;
    };
    $runtime->throw_exception( $@ ) unless $ok;

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

    my $re = $runtime->compile_regex( $string->as_string( $runtime ),
                                      $op->{flags} );
    push @{$runtime->{_stack}}, $re;

    return $pc + 1;
}

1;
