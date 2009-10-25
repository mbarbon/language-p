package Language::P::Intermediate::Transform;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(_temporary_count _current_basic_block
                              _converting _queue _stack _converted
                              _converted_segments) );

use Language::P::Opcodes qw(:all);
use Language::P::Assembly qw(:all);

my %op_map =
  ( OP_MAKE_LIST()        => '_make_list',
    OP_POP()              => '_pop',
    OP_SWAP()             => '_swap',
    OP_DUP()              => '_dup',
    OP_CONSTANT_SUB()     => '_const_sub',
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

sub _local_name { ++$_[0]->{_temporary_count} }

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

sub _opcode_set {
    my $op = opcode_n( OP_SET, $_[1] );
    $op->{attributes}{index} = $_[0];

    return $op;
}

sub all_to_tree {
    my( $self, $code_segments ) = @_;
    my $all_ssa = $self->all_to_ssa( $code_segments );

    _ssa_to_tree( $self, $_ ) foreach @$all_ssa;

    return $all_ssa;
}

sub all_to_ssa {
    my( $self, $code_segments ) = @_;

    $self->_converted_segments( {} );
    my @converted = map    $self->_converted_segments->{$_}
                        || $self->to_ssa( $_ ), @$code_segments;
    $self->_converted_segments( {} );

    return \@converted;
}

sub to_ssa {
    my( $self, $code_segment ) = @_;

    $self->_temporary_count( 0 );
    $self->_stack( [] );
    $self->_converted( {} );

    my $new_code = Language::P::Intermediate::Code->new
                       ( { type           => $code_segment->type,
                           name           => $code_segment->name,
                           basic_blocks   => [],
                           lexicals       => $code_segment->lexicals,
                           scopes         => $code_segment->scopes,
                           lexical_states => $code_segment->lexical_states,
                           } );
    $self->_converted_segments->{$code_segment} = $new_code;

    foreach my $inner ( @{$code_segment->inner} ) {
        next unless $inner;
        my $new_inner = $self->to_ssa( $inner );
        $new_inner->{outer} = $new_code;
        push @{$new_code->inner}, $new_inner;
    }

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
        # process a node with input values after all its predecessors
        # might not be possible if more values become temporaries,
        # works for now
        if(    ( $self->_converted->{$block}{depth} || 0 ) > 0
            && grep !$self->_converted->{$_}{converted}, @{$block->predecessors} ) {
            push @{$self->_queue}, $block;
            redo;
        }
        $self->_converted->{$block} =
          { %{$self->_converted->{$block}},
            converted => 1,
            created   => 0,
            };
        $self->_converting( $self->_converted->{$block} );
        my $cblock = $self->_converting->{block} ||=
            Language::P::Intermediate::BasicBlock
                ->new_from_label( $block->start_label,
                                  $block->lexical_state,
                                  $block->scope );

        push @{$new_code->basic_blocks}, $cblock;
        $self->_current_basic_block( $cblock );
        @$stack = @{$self->_converting->{in_stack} || []};

        # remove dummy phi values that all get the same value
        foreach my $value ( @$stack ) {
            next unless $value->{opcode_n} == OP_PHI;
            my $t = $value->{parameters}[1];
            if( !grep $value->{parameters}[$_] != $t,
                grep  $_ & 1,
                      1 .. $#{$value->{parameters}} ) {
                $value = opcode_nm( OP_GET, index => $t );
            }
        }

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

    return _ssa_to_tree( $self, $ssa );
}

sub _ssa_to_tree {
    my( $self, $ssa ) = @_;

    $self->_temporary_count( 0 );

    foreach my $block ( @{$ssa->basic_blocks} ) {
        my $op_off = 0;
        while( $op_off <= $#{$block->bytecode} ) {
            my $op = $block->bytecode->[$op_off];
            ++$op_off;
            next if    $op->{label}
                    || $op->{opcode_n} != OP_SET
                    || $op->{parameters}[0]->{opcode_n} != OP_PHI;

            my %block_variable = @{$op->{parameters}[0]->{parameters}};

            while( my( $label, $variable ) = each %block_variable ) {
                my( $block_from ) = grep $_ eq $label,
                                         @{$ssa->basic_blocks};
                my $op_from_off = $#{$block_from->bytecode};

                # find the jump coming to this block
                while( $op_from_off >= 0 ) {
                    my $op_from = $block_from->bytecode->[$op_from_off];
                    last if    $op_from->{attributes}
                            && exists $op_from->{attributes}{to}
                            && $op_from->{attributes}{to} eq $block;
                    --$op_from_off;
                }

                die "Can't find jump: ", $block_from->start_label,
                    " => ", $block->start_label
                    if $op_from_off < 0;

                # add SET nodes to rename the variables
                splice @{$block_from->bytecode}, $op_from_off, 0,
                       _opcode_set( $op->{attributes}{index},
                                    opcode_nm( OP_GET, index => $variable ) );
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
        _add_bytecode $self, _opcode_set( $name, $value );
        $value = opcode_nm( OP_GET, index => $name );
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
            if( @{$to->predecessors} > 1 ) {
                $converted->{in_stack} = [ map opcode_n( OP_PHI ), @$stack ];
            } else {
                $converted->{in_stack} = [ map opcode_nm( OP_GET, index => $_ ),
                                               @$out_names ];
            }
        }

        # update PHI nodes with the (block, value) pair
        if( @{$to->predecessors} > 1 ) {
            my $i = 0;
            foreach my $out ( @$out_names ) {
                die "Node with multiple predecessors has no phi ($i)"
                    unless $converted->{in_stack}[$i]->{opcode_n} == OP_PHI;
                push @{$converted->{in_stack}[$i]{parameters}},
                     $self->_current_basic_block, $out;
                ++$i;
            }
        }
    }

    $converted->{depth} = @$stack;
    $converted->{block} ||= Language::P::Intermediate::BasicBlock
                                ->new_from_label( $to->start_label,
                                                  $to->lexical_state,
                                                  $to->scope );
    $op->{attributes}{to} = $converted->{block};
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
    @out_names = map $_->{attributes}{index}, @out_stack;
    for( my $j = $i; $i < @$stack; ++$i, ++$j ) {
        my $op = $stack->[$i];
        if( $op->{opcode_n} == OP_GET ) {
            $out_names[$j] = $op->{attributes}{index};
            $out_stack[$i] = $op;
        } else {
            $out_names[$j] = _local_name( $self );
            $out_stack[$i] = opcode_nm( OP_GET, index => $out_names[$j] );
            _add_bytecode $self, _opcode_set( $out_names[$j], $op );
        }
    }
    @$stack = @out_stack;

    return @out_names;
}

sub _generic {
    my( $self, $op ) = @_;
    my $attrs = $OP_ATTRIBUTES{$op->{opcode_n}};
    my $in_args = ( $attrs->{flags} & Language::P::Opcodes::FLAG_VARIADIC ) ?
                      $op->{attributes}{arg_count} : $attrs->{in_args};
    my @in = $in_args ? _get_stack( $self, $in_args ) : ();
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

sub _const_sub {
    my( $self, $op ) = @_;
    my $new_seg = $self->_converted_segments->{$op->{attributes}{value}};
    my $new_op = opcode_nm( OP_CONSTANT_SUB(), value => $new_seg );

    push @{$self->_stack}, $new_op;
    _created( $self, 1 );
}

sub _pop {
    my( $self, $op ) = @_;

    die 'Empty stack in pop' unless @{$self->_stack} >= 1;
    my $top = pop @{$self->_stack};
    _add_bytecode $self, $top if    $top->{opcode_n} != OP_PHI
                                 && $top->{opcode_n} != OP_GET;
    _emit_out_stack( $self );
    _created( $self, -1 );
}

sub _dup {
    my( $self, $op ) = @_;

    die 'Empty stack in dup' unless @{$self->_stack} >= 1;
    my( $v ) = _get_stack( $self, 1, 1 );
    push @{$self->_stack}, $v, $v;
    _created( $self, 2 );
}

sub _swap {
    my( $self, $op ) = @_;
    my $stack = $self->_stack;
    my $t = $stack->[-1];

    die 'Empty stack in swap' unless @{$self->_stack} >= 2;
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
