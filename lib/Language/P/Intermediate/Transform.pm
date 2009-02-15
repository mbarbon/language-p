package Language::P::Intermediate::Transform;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(_temporary_count _current_basic_block
                              _converting _queue _stack _converted) );

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

    # find all non-empty blocks without predecessors and enqueue them
    # (there can be more than one only if there is dead code)
    $self->_queue( [] );
    foreach my $block ( @{$code_segment->basic_blocks} ) {
        next unless @{$block->bytecode};
        next if @{$block->predecessors};
        push @{$self->_queue}, $block;
    }

    my $stack = $self->_stack;
    while( @{$self->_queue} ) {
        my $block = shift @{$self->_queue};

        next if $self->_converted->{$block}{converted};
        $self->_converted->{$block} =
          { %{$self->_converted->{$block}},
            converted => 1,
            created   => 0,
            };
        $self->_converting( $self->_converted->{$block} );
        my $cblock = $self->_converting->{block} ||=
            Language::P::Intermediate::BasicBlock
                ->new_from_label( $block->start_label );

        push @{$new_code->basic_blocks}, $cblock;
        $self->_current_basic_block( $cblock );
        @$stack = @{$self->_converting->{in_stack} || []};
        $self->_converting->{depth} = scalar @$stack;

        foreach my $bc ( @{$block->bytecode} ) {
            next if $bc->{label};
            my $meth = $op_map{$bc->{opcode_n}} || '_generic';

            $self->$meth( $bc );
        }

        _add_bytecode $self,
            grep $_->{opcode_n} != OP_PHI && $_->{opcode_n} != OP_GET, @$stack;
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

                # find the jump coming to this block
                while( $op_from_off >= 0 ) {
                    my $op_from = $block_from->bytecode->[$op_from_off];
                    last if    $op_from->{parameters}
                            && @{$op_from->{parameters}}
                            && $op_from->{parameters}[-1] eq $block;
                    --$op_from_off;
                }

                die "Can't find jump: ", $block_from->start_label,
                    " => ", $block->start_label
                    if $op_from_off < 0;

                # add SET nodes to rename the variables
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
    my( $self, $count, $force_get ) = @_;
    return unless $count;
    my @values = splice @{$self->_stack}, -$count;
    _created( $self, -$count );

    foreach my $value ( @values ) {
        next if $value->{opcode_n} != OP_PHI && !$force_get;
        my $name = _local_name( $self );
        _add_bytecode $self, opcode_n( OP_SET, $name, $value );
        $value = opcode_n( OP_GET, $name );
    }

    return @values;
}

sub _jump_to {
    my( $self, $op, $to, $out_names ) = @_;

    my $stack = $self->_stack;
    my $converted_blocks = $self->_converted;
    my $converted = $converted_blocks->{$to} ||= {};

    # check that input stack height is the same on all in branches
    if( defined $converted->{depth} ) {
        die sprintf "Inconsistent depth %d != %d in %s => %s",
            $converted->{depth}, scalar @$stack,
            $self->_current_basic_block->start_label, $to->start_label
            if $converted->{depth} != scalar @$stack;
    }

    # emit as OP_SET all stack elements created in the basic block
    # and construct the input stack of the next basic block
    if( @$stack ) {
        @$out_names = _emit_out_stack( $self ) unless @$out_names;

        my $created_elements = $self->_converting->{created};
        my $inherited_elements = @$stack - $created_elements;

        # copy inherited elements, generated GET or PHI for created elements
        if( !$converted->{in_stack} ) {
            my $in = $converted->{in_stack} =
                [ @{$stack}[0 .. $inherited_elements - 1] ];
            if( @{$to->predecessors} > 1 ) {
                push @$in, map opcode_n( OP_PHI ), 1 .. $created_elements;
            } else {
                push @$in, map opcode_n( OP_GET, $_ ), @$out_names;
            }
        }

        # update PHI nodes with the (block, value) pair
        if( @{$to->predecessors} > 1 ) {
            my $i = $inherited_elements;
            foreach my $out ( @$out_names ) {
                die "Node with multiple predecessors has no phi ($i)"
                    unless $converted->{in_stack}[$i]->{opcode_n} == OP_PHI;
                push @{$converted->{in_stack}[$i]{parameters}},
                     $self->_current_basic_block, $out;
                ++$i;
            }
        }
    }

    $converted->{block} ||= Language::P::Intermediate::BasicBlock
                                ->new_from_label( $to->start_label );
    push @{$op->{parameters}}, $converted->{block};
    push @{$self->_queue}, $to;

    return $out_names;
}

sub _emit_out_stack {
    my( $self ) = @_;
    my $stack = $self->_stack;
    return unless @$stack;

    # add named targets for all trees in stack, emit
    # them and replace stack with the targets
    my( @out_names, @out_stack );
    my $i = @$stack - $self->_converting->{created};

    # copy inherited stack elements and all created GET opcodes add a
    # SET in the block and a GET in the out stack for all other
    # created ops
    @out_stack = @{$stack}[0 .. $i - 1];
    for( my $j = 0; $i < @$stack; ++$i, ++$j ) {
        my $op = $stack->[$i];
        if( $op->{opcode_n} == OP_GET ) {
            $out_names[$j] = $op->{parameters}[0];
            $out_stack[$i] = $op;
        } else {
            $out_names[$j] = _local_name( $self );
            $out_stack[$i] = opcode_n( OP_GET, $out_names[$j] );
            _add_bytecode $self, opcode_n( OP_SET, $out_names[$j], $op );
        }
    }
    @$stack = @out_stack;

    return @out_names;
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
        _emit_out_stack( $self );
        _add_bytecode $self, $new_op;
    } elsif( $attrs->{out_args} == 1 ) {
        push @{$self->_stack}, $new_op;
        _created( $self, 1 );
    } else {
        die "Unhandled out_args value: ", $attrs->{out_args};
    }
}

sub _pop {
    my( $self, $op ) = @_;

    die 'Oops' unless @{$self->_stack} >= 1;
    my $top = pop @{$self->_stack};
    _add_bytecode $self, $top if    $top->{opcode_n} != OP_PHI
                                 && $top->{opcode_n} != OP_GET;
    _emit_out_stack( $self );
    _created( $self, -1 );
}

sub _dup {
    my( $self, $op ) = @_;

    die 'Oops' unless @{$self->_stack} >= 1;
    my( $v ) = _get_stack( $self, 1, 1 );
    push @{$self->_stack}, $v, $v;
    _created( $self, 2 );
}

sub _swap {
    my( $self, $op ) = @_;
    my $stack = $self->_stack;
    my $t = $stack->[-1];

    die 'Oops' unless @{$self->_stack} >= 2;
    $stack->[-1] = $stack->[-2];
    $stack->[-2] = $t;
}

sub _make_list {
    my( $self, $op ) = @_;

    push @{$self->_stack},
         opcode_n( OP_MAKE_LIST, _get_stack( $self, $op->{attributes}{count} ) );
    _created( $self, 1 );
}

sub _cond_jump {
    my( $self, $op ) = @_;
    my $attrs = $OP_ATTRIBUTES{$op->{opcode_n}};
    my @in = _get_stack( $self, $attrs->{in_args} );
    my $new_cond = opcode_n( $op->{opcode_n}, @in );
    my $new_jump = opcode_n( OP_JUMP );

    my @out_names;
    _jump_to( $self, $new_cond, $op->{attributes}{true}, \@out_names );
    _add_bytecode $self, $new_cond;
    _jump_to( $self,$new_jump,  $op->{attributes}{false}, \@out_names );
    _add_bytecode $self, $new_jump;
}

sub _jump {
    my( $self, $op ) = @_;
    my $new_jump = opcode_nm( $op->{opcode_n} );

    _jump_to( $self, $new_jump, $op->{attributes}{to}, [] );
    _add_bytecode $self, $new_jump;
}

sub _created {
    my( $self, $count ) = @_;

    $self->_converting->{created} += $count;
    if( $count < 0 && $self->_converting->{created} < 0 ) {
        $self->_converting->{created} = 0;
    }
}

1;
