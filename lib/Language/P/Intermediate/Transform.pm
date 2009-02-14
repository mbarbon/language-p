package Language::P::Intermediate::Transform;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(_temporary_count _current_basic_block
                              _out_names _queue _stack _converted) );

use Language::P::Opcodes qw(:all);
use Language::P::Assembly qw(:all);

my %op_map =
  ( OP_MAKE_LIST()        => '_make_list',
    OP_POP()              => '_pop',
    OP_SWAP()             => '_swap',
    OP_DUP()              => '_dup',
    OP_JUMP_IF_TRUE()     => '_cond_jump',
    OP_JUMP_IF_FALSE()    => '_cond_jump',
    OP_JUMP_IF_NULL()     => '_cond_jump',
    OP_JUMP_IF_F_GT()     => '_cond_jump',
    OP_JUMP_IF_F_GE()     => '_cond_jump',
    OP_JUMP_IF_F_EQ()     => '_cond_jump',
    OP_JUMP_IF_F_NE()     => '_cond_jump',
    OP_JUMP_IF_F_LE()     => '_cond_jump',
    OP_JUMP_IF_F_LT()     => '_cond_jump',
    OP_JUMP_IF_S_GT()     => '_cond_jump',
    OP_JUMP_IF_S_GE()     => '_cond_jump',
    OP_JUMP_IF_S_EQ()     => '_cond_jump',
    OP_JUMP_IF_S_NE()     => '_cond_jump',
    OP_JUMP_IF_S_LE()     => '_cond_jump',
    OP_JUMP_IF_S_LT()     => '_cond_jump',
    OP_JUMP()             => '_jump',
    );

sub _local_name { sprintf "t%d", ++$_[0]->{_temporary_count} }

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->_temporary_count( 0 );

    return $self;
}

sub _add_bytecode {
    my( $self, @bytecode ) = @_;

    push @{$self->_current_basic_block->bytecode}, @bytecode;
}

sub to_ssa {
    my( $self, $code_segment ) = @_;

    $self->_temporary_count( 0 );
    $self->_stack( [] );
    $self->_converted( {} );

    my $new_code = Language::P::Intermediate::Code->new
                       ( { type         => $code_segment->type,
                           name         => $code_segment->name,
                           basic_blocks => [],
                           lexicals     => $code_segment->lexicals,
                           } );

    # find first non-empty block
    foreach my $block ( @{$code_segment->basic_blocks} ) {
        next unless @{$block->bytecode};
        $self->_queue( [ { block => $block } ] );
        last;
    }

    my $stack = $self->_stack;
    while( @{$self->_queue} ) {
        my $e = shift @{$self->_queue};
        my $block = $e->{block};

        next if $self->_converted->{$block}{converted};
        @$stack = @{$e->{in_stack} || []};
        $self->_out_names( undef );
        my $cblock = Language::P::Intermediate::BasicBlock->new
                         ( { start_label => $block->start_label,
                             bytecode    => [],
                             } );
        push @{$new_code->basic_blocks}, $cblock;
        $self->_current_basic_block( $cblock );

        my $patch = $self->_converted->{$block}{patch};
        $self->_converted->{$block} =
          { depth     => scalar @$stack,
            in_stack  => $e->{in_stack} || [],
            in_names  => $e->{in_names} || [],
            converted => 1,
            block     => $cblock,
            };
        if( $patch ) {
            push @{$_->{parameters}}, $cblock foreach @$patch;
        }

        foreach my $bc ( @{$block->bytecode} ) {
            next if $bc->{label};
            my $meth = $op_map{$bc->{opcode_n}} || '_generic';

            $self->$meth( $bc );
        }

        foreach my $op ( @$stack ) {
            next if $op->{opcode_n} == OP_PHI || $op->{opcode_n} == OP_GET;
            _add_bytecode $self, $op;
        }
    }

    return $new_code;
}

sub to_tree {
    my( $self, $code_segment ) = @_;
    my $ssa = $self->to_ssa( $code_segment );

    $self->_temporary_count( 0 );

    foreach my $block ( @{$ssa->basic_blocks} ) {
        my $op_off = 0;
        while( $op_off <= $#{$block->bytecode} ) {
            my $op = $block->bytecode->[$op_off];
            ++$op_off;
            next if    $op->{label}
                    || $op->{opcode_n} != OP_SET
                    || $op->{parameters}[1]->{opcode_n} != OP_PHI;

            my %block_variable = @{$op->{parameters}[1]->{parameters}};

            while( my( $label, $variable ) = each %block_variable ) {
                my( $block_from ) = grep $_ eq $label,
                                         @{$ssa->basic_blocks};
                my $op_from_off = $#{$block_from->bytecode};

                while( $op_from_off >= 0 ) {
                    my $op_from = $block_from->bytecode->[$op_from_off];
                    last if    $op_from->{parameters}
                            && @{$op_from->{parameters}}
                            && $op_from->{parameters}[-1] eq $block;
                    --$op_from_off;
                }

                die "Can't find jump" if $op_from_off < 0;

                splice @{$block_from->bytecode}, $op_from_off, 0,
                       opcode_n( OP_SET, $op->{parameters}[0],
                                         opcode_n( OP_GET, $variable ) );
            }

            --$op_off;
            splice @{$block->bytecode}, $op_off, 1;
        }
    }

    return $ssa;
}

sub _get_stack {
    my( $self, $count ) = @_;
    my @values = splice @{$self->_stack}, -$count;

    foreach my $value ( @values ) {
        next unless $value->{opcode_n} == OP_PHI;
        my $name = _local_name( $self );
        _add_bytecode $self, opcode_n( OP_SET, $name, $value );
        $value = opcode_n( OP_GET, $name );
    }

    return @values;
}

sub _jump_to {
    my( $self, $op, $to ) = @_;

    my $stack = $self->_stack;
    my $converted = $self->_converted;
    if( defined $converted->{$to}->{depth} ) {
        die sprintf "Inconsistent depth %d != %d",
            $converted->{$to}->{depth}, scalar @$stack
            if $converted->{$to}->{depth} != scalar @$stack;
    }

    if( @$stack ) {
        $self->_out_names( [ map _local_name( $self ), @$stack ] )
          unless $self->_out_names;
        _emit_out_stack( $self, $self->_out_names );

        $converted->{$to}->{in_names} ||= [ map _local_name( $self ), @$stack ];
        $converted->{$to}->{in_stack} ||= [ map opcode_n( OP_PHI ), @$stack ];

        my $i = 0;
        foreach my $out ( @{$self->_out_names} ) {
            push @{$converted->{$to}->{in_stack}[$i]{parameters}},
                 $self->_current_basic_block, $out;
            ++$i;
        }

        push @{$self->_queue},
             { in_stack => $converted->{$to}->{in_stack},
               in_names => $converted->{$to}->{in_names},
               block    => $to,
               };
    } else {
        push @{$self->_queue}, { block => $to };
    }

    if( $converted->{$to}{converted} ) {
        push @{$op->{parameters}}, $converted->{$to}->{block};
    } else {
        push @{$converted->{$to}{patch}}, $op;
    }
}

sub _emit_out_stack {
    my( $self, $out_names ) = @_;
    my $stack = $self->_stack;
    return unless @$stack;

    # add named targets for all trees in stack, emit
    # them and replace stack with the targets
    $out_names ||= [];
    my $out_stack = [];
    for( my $i = 0; $i < @$stack; ++$i ) {
        my $op = $stack->[$i];
        if( $op->{opcode_n} == OP_GET ) {
            $out_names->[$i] = $op->{parameters}[0];
            $out_stack->[$i] = $op;
        } else {
            $out_names->[$i] ||= _local_name( $self );
            $out_stack->[$i] = opcode_n( OP_GET, $out_names->[$i] );
            _add_bytecode $self, opcode_n( OP_SET, $out_names->[$i], $op );
        }
    }

    @$stack = @$out_stack;
}

sub _generic {
    my( $self, $op ) = @_;
    my $attrs = $OP_ATTRIBUTES{$op->{opcode_n}};
    my @in = $attrs->{in_args} ? _get_stack( $self, $attrs->{in_args} ) : ();
    my $new_op;

    if( $op->{attributes} ) {
        $new_op = opcode_nm( $op->{opcode_n}, %{$op->{attributes}} );
        $new_op->{parameters} = \@in if @in;
    } elsif( $op->{parameters} ) {
        die "Can't handle fixed and dynamic parameters" if @in;
        $new_op = opcode_n( $op->{opcode_n}, @{$op->{parameters}} );
    } else {
        $new_op = opcode_n( $op->{opcode_n}, @in );
    }

    if( !$attrs->{out_args} ) {
        _add_bytecode $self, $new_op;
        _emit_out_stack( $self );
    } elsif( $attrs->{out_args} == 1 ) {
        push @{$self->_stack}, $new_op;
    } else {
        die "Unhandled out_args value: ", $attrs->{out_args};
    }
}

sub _pop {
    my( $self, $op ) = @_;

    my $top = pop @{$self->_stack};
    _add_bytecode $self, $top if    $top->{opcode_n} != OP_PHI
                                 && $top->{opcode_n} != OP_GET;
    _emit_out_stack( $self );
}

sub _dup {
    my( $self, $op ) = @_;

    _emit_out_stack( $self );
    push @{$self->_stack}, $self->_stack->[-1];
}

sub _swap {
    my( $self, $op ) = @_;
    my $stack = $self->_stack;
    my $t = $stack->[-1];

    $stack->[-1] = $stack->[-2];
    $stack->[-2] = $t;
}

sub _make_list {
    my( $self, $op ) = @_;

    push @{$self->_stack}, opcode_n( OP_MAKE_LIST, _get_stack( $self, $op->{attributes}{count} ) );
}

sub _cond_jump {
    my( $self, $op ) = @_;
    my $attrs = $OP_ATTRIBUTES{$op->{opcode_n}};
    my @in = _get_stack( $self, $attrs->{in_args} );
    my $new_cond = opcode_n( $op->{opcode_n}, @in );
    my $new_jump = opcode_n( OP_JUMP );

    _jump_to( $self, $new_cond, $op->{attributes}{true} );
    _add_bytecode $self, $new_cond;
    _jump_to( $self,$new_jump,  $op->{attributes}{false} );
    _add_bytecode $self, $new_jump;
}

sub _jump {
    my( $self, $op ) = @_;
    my $new_jump = opcode_nm( $op->{opcode_n} );

    _jump_to( $self, $new_jump, $op->{attributes}{to} );
    _add_bytecode $self, $new_jump;
}

1;
