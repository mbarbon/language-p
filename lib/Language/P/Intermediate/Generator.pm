package Language::P::Intermediate::Generator;

use strict;
use warnings;
use parent qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_accessors( qw(_code_segments _current_basic_block _options
                              _label_count _temporary_count _current_block
                              _current_lexical_state _stack _local_count
                              _current_subroutine _in_args_map _needed
                              _group_count _pos_count _main _lexicals
                              file_name) );
__PACKAGE__->mk_ro_accessors( qw(is_stack) );

use Language::P::Opcodes qw(:all);
use Language::P::ParseTree::PropagateContext;
use Language::P::Constants qw(:all);
use Language::P::Keywords qw(:all);
use Language::P::Assembly qw(:all);

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->_options( {} ) unless $self->_options;

    return $self;
}

sub set_option {
    my( $self, $option, $value ) = @_;

    if( $option eq 'dump-ir' ) {
        $self->_options->{$option} = 1;
    }

    return 0;
}

# determine the slot type for the result value of an opcode
sub _slot_type {
    my( $self, $op ) = @_;
    my $opn = $op->opcode_n;

    if(    $opn == OP_GLOB_SLOT
        || $opn == OP_GLOBAL
        || $opn == OP_TEMPORARY
        || $opn == OP_GET ) {
        my $slot = $op->slot;
        die "Undefined slot for $opn" unless $slot;

        # for now, make no difference between scalars and globs
        return VALUE_SCALAR if $slot == VALUE_GLOB;
        # stashes really are just hashes
        return VALUE_HASH if $slot == VALUE_STASH;

        return $slot;
    }
    if(    $opn == OP_LEXICAL
        || $opn == OP_LEXICAL_PAD ) {
        my $index = $op->lex_index;
        my $slot;

        if( $opn == OP_LEXICAL ) {
            $slot = $self->_lexicals->{$self->_current_subroutine}{lex_idx}[$index]->sigil;
        } else {
            $slot = $self->_lexicals->{$self->_current_subroutine}{pad_idx}[$index]->sigil;
        }

        die "Undefined slot for $opn" unless $slot;

        # for now, make no difference between scalars and globs
        return VALUE_SCALAR if $slot == VALUE_GLOB;
        # stashes really are just hashes
        return VALUE_HASH if $slot == VALUE_STASH;

        return $slot;
    }
    if(    $opn == OP_DEREFERENCE_ARRAY
        || $opn == OP_VIVIFY_ARRAY ) {
        # for now, make no difference between lists and arrays
        return VALUE_INDEXABLE;
    }
    if(    $opn == OP_MAKE_ARRAY
        || $opn == OP_MAKE_LIST ) {
        # for now, make no difference between lists and arrays
        return VALUE_ARRAY;
    }
    if(    $opn == OP_DEREFERENCE_HASH
        || $opn == OP_VIVIFY_HASH ) {
        return VALUE_HASH;
    }
    if(    $opn == OP_CONSTANT_SUB
        || $opn == OP_DEREFERENCE_SUB
        || $opn == OP_FIND_METHOD ) {
        return VALUE_SUB;
    }
    if( $opn == OP_PHI ) {
        my $slot = $op->slots->[0];
        die "Undefined slot for OP_PHI" unless $slot;

        # unify the values coming from the different basic blocks
        foreach my $s ( @{$op->slots} ) {
            $slot = _unify_slot_types( $slot, $s );
        }

        return $slot;
    }

    # these are never transmitted across blocks (not unless codegen changes)
    if(    $opn == OP_CONSTANT_REGEX
        || $opn == OP_ITERATOR ) {
        die "Should not happen";
    }

    # defaul to a scalar value
    return VALUE_SCALAR;
}

# determine the common supertype of two slot types
sub _unify_slot_types {
    my( $a, $b ) = @_;

    return $a if $a == $b;

    ( $a, $b ) = ( $b, $a ) if $b == VALUE_SCALAR;

    if( $a == VALUE_SCALAR ) {
        if(    $b == VALUE_SCALAR
            || $b == VALUE_ARRAY
            || $b == VALUE_INDEXABLE
            || $b == VALUE_HASH ) {
            return VALUE_SCALAR;
        }

        require Carp;

        Carp::confess( "Unable to unify" );
    }

    if(    ( $a == VALUE_ARRAY || $a == VALUE_INDEXABLE )
        && ( $b == VALUE_ARRAY || $b == VALUE_INDEXABLE ) ) {
        return VALUE_ARRAY;
    }

    # $a != $b and no unification is possible
    require Carp;

    Carp::confess( "Unable to unify" );
}

sub _add_value {
    my( $self, $op ) = @_;

    push @{$self->_stack}, $op;
}

sub _add_bytecode {
    my( $self, @bytecode ) = @_;

    push @{$self->_current_basic_block->bytecode}, @bytecode;
}

sub _add_jump {
    my( $self, $op, @to ) = @_;

    _leave_current_basic_block( $self );
    if( _needed( $self ) ) {
        $self->_current_basic_block->add_jump_unoptimized( $op, @to );
    } else {
        $self->_current_basic_block->add_jump( $op, @to );
    }
}

sub _add_jump_unoptimized {
    my( $self, $op, @to ) = @_;

    _leave_current_basic_block( $self );
    $self->_current_basic_block->add_jump_unoptimized( $op, @to );
}

sub _fake_stack {
    my( $count ) = @_;

    # fake stack; since the block is dead code, there is no need for
    # real values
    return [ map opcode_nm( OP_GET, index => -1, slot => 0 ), 0 .. $count ];
}

sub _create_in_stack {
    my( $self, $vars ) = @_;
    my @stack;

    foreach my $var ( @$vars ) {
        push @stack,
             opcode_nm( OP_GET,
                        index => $var->[0],
                        slot  => $var->[1] );
    }

    return \@stack;
}

sub _add_blocks {
    my( $self, $block ) = @_;

    _check_split_edges( $self, $block ) if @{$block->predecessors} > 1;
    push @{$self->_code_segments->[0]->basic_blocks}, $block;
    if(    @{$block->predecessors}
        && exists $self->_in_args_map->{$block->predecessors->[0]} ) {
        my @stack;
        foreach my $i ( 0 .. $#{$self->_in_args_map->{$block->predecessors->[0]}} ) {
            my( @slots, @blocks, @vars, $slot, $diff );
            foreach my $pred ( @{$block->predecessors} ) {
                my $val = $self->_in_args_map->{$pred}[$i];
                push @blocks, $pred;
                push @vars, $val->[0];
                push @slots, $val->[1];
                $diff ||= $vars[0] != $vars[-1];
                $slot = $slot ? _unify_slot_types( $slot, $val->[1] ) : $val->[1];
            }

            if( $diff && !$self->is_stack ) {
                push @stack,
                     opcode_nm( OP_PHI,
                                slots   => \@slots,
                                blocks  => \@blocks,
                                indices => \@vars );
            } else {
                push @stack,
                     opcode_nm( OP_GET,
                                index => $vars[0],
                                slot  => $slot );
            }
        }

        $self->_stack( \@stack );
    }
    _current_basic_block( $self, $block );
    _needed( $self, 0 );
}

sub _local_name { ++$_[0]->{_local_count} }

sub _get_stack {
    my( $self, $count ) = @_;
    return undef unless $count;

    if( @{$self->_stack} < $count ) {
        require Carp;

        Carp::confess( 'Shallow stack ', $count, ' in ',
                       $self->_current_basic_block->start_label );
    }

    my @values = splice @{$self->_stack}, -$count;
    return \@values if $self->is_stack;

    foreach my $value ( @values ) {
        next if $value->opcode_n != OP_PHI;
        my $name = _local_name( $self );
        my $slot = _slot_type( $self, $value );
        _add_bytecode $self,
            opcode_npam( OP_SET, $value->pos, [ $value ],
                         index => $name,
                         slot  => $slot );
        $value = opcode_npm( OP_GET, $value->pos,
                             index => $name,
                             slot  => $slot );
    }

    return \@values;
}

sub _leave_current_basic_block {
    my( $self ) = @_;

    if( @{$self->_stack} ) {
        $self->_in_args_map->{$self->_current_basic_block} = _emit_out_stack( $self );
        $self->_stack( [] );
    }
}

sub _dump_out_stack {
    my( $self ) = @_;

    $self->_stack( _create_in_stack( $self, _emit_out_stack( $self ) ) );
}

sub _pop {
    my( $self ) = @_;
    my $top = pop @{$self->_stack};

    if( $self->is_stack ) {
        _add_bytecode $self, opcode_nam( OP_POP, [ $top ] );
    } elsif( $top->opcode_n != OP_GET && $top->opcode_n != OP_PHI ) {
        _add_bytecode $self, $top;
    }
    _needed( $self, 1 );
}

sub _dup {
    my( $self ) = @_;

    push @{$self->_stack}, $self->_stack->[-1];
    _add_bytecode $self, opcode_n( OP_DUP )
        if $self->is_stack;
}

sub _emit_out_stack {
    my( $self ) = @_;
    my $stack = $self->_stack;
    return unless @$stack;

    my @out_names;
    foreach my $op ( @{$stack} ) {
        if( $op->opcode_n == OP_GET ) {
            push @out_names, [ $op->index, $op->slot ];
        } else {
            my $index = _local_name( $self );
            my $slot = _slot_type( $self, $op );
            push @out_names, [ $index, $slot ];
            if( $self->is_stack ) {
                _add_bytecode $self, $op;
            } else {
                _add_bytecode $self,
                    opcode_npam( OP_SET, $op->pos, [ $op ],
                                 index => $index,
                                 slot  => $slot );
            }
        }
    }

    return \@out_names;
}

sub _new_blocks { map _new_block( $_[0] ), 1 .. $_[1] }
sub _new_block {
    my( $self ) = @_;
    my $block = $self->_current_block;

    return Language::P::Intermediate::BasicBlock->new_from_label
               ( 'L' . ++$self->{_label_count},
                 ( $block ? $block->id : 0 ), 1 );
}

sub _new_fake_block {
    my( $self ) = @_;

    # there are assumptions elsewhere that basic blocks for the same
    # scope are contiguous, so the scope id must be the correct one
    return Language::P::Intermediate::BasicBlock->new_from_label
               ( 'L0', $self->_current_block->id, 2 );
}

sub _start_bb {
    my( $self ) = @_;
    return if @{$self->_current_basic_block->bytecode} == 0;
    my $block = _new_block( $self );

    _add_jump $self,
        opcode_nm( OP_JUMP, to => $block ), $block;
    _add_blocks $self, $block;

    return $block;
}

sub _check_split_edges {
    my( $self, $current ) = @_;
    return if @{$current->predecessors} < 2;

    # remove edges from a node with multiple successors to a node
    # with multiple predecessors by inserting an empty node and
    # splitting the edge
    my @pred = @{$current->predecessors};
    foreach my $block ( @pred ) {
        next if @{$block->successors} != 2;

        my $new_block = _new_block( $self );
        push @{$self->_code_segments->[0]->basic_blocks}, $new_block;
        $new_block->add_jump_unoptimized( opcode_nm( OP_JUMP, to => $current ), $current );
        $block->_change_successor( $current, $new_block );
        $self->_in_args_map->{$new_block} = $self->_in_args_map->{$block};
    }
}

sub _context { $_[0]->get_attribute( 'context' ) & CXT_CALL_MASK }
sub _context_lvalue { $_[0]->get_attribute( 'context' ) & (CXT_CALL_MASK|CXT_LVALUE|CXT_NOCREATE) }

sub push_block {
    my( $self, $flags, $start_pos, $exit_pos, $context ) = @_;
    my $id = @{$self->_code_segments->[0]->scopes};
    my $outer = $self->_current_block;

    if( @{$self->_current_basic_block->bytecode} != 0 ) {
        require Carp;

        Carp::confess( "Instructions at scope start" );
    }
    $self->_current_basic_block->set_scope( $id );

    push @{$self->_code_segments->[0]->scopes},
         Language::P::Intermediate::Scope->new
             ( { outer         => $outer ? $outer->id : -1,
                 id            => $id,
                 flags         => $flags,
                 context       => $context || 0, # for eval BLOCK only
                 exception     => undef, # for eval BLOCK only
                 pos_s         => $start_pos,
                 pos_e         => $exit_pos,
                 lexical_state => $self->_current_lexical_state || 0,
                 } );

    $self->_current_block( $self->_code_segments->[0]->scopes->[-1] );
    $self->_current_lexical_state( $outer ? $outer->lexical_state : 0 );

    return $self->_current_block;
}

sub _outer_scope {
    my( $self, $scope ) = @_;

    return $scope->outer == -1 ? undef :
               $self->_code_segments->[0]->scopes->[$scope->outer];
}

sub pop_block {
    my( $self ) = @_;
    my $to_ret = $self->_current_block;
    my $outer = _outer_scope( $self, $to_ret );

    $self->_current_block( $outer );
    $self->_current_lexical_state( $outer ? $outer->lexical_state : 0 );

    return $to_ret;
}

sub create_main {
    my( $self, $outer, $is_eval ) = @_;
    my $main = Language::P::Intermediate::Code->new
                   ( { type         => $is_eval ? CODE_EVAL : CODE_MAIN,
                       name         => undef,
                       basic_blocks => [],
                       outer        => $outer,
                       lexicals     => [],
                       prototype    => undef,
                       } );
    $self->_lexicals( {} ) unless $is_eval;
    $self->_lexicals->{$main}{max_stack} = 0,
    $self->_main( $main );
}

sub create_eval_context {
    my( $self, $indices, $lexicals ) = @_;
    my( $lex, $lex_idx, $pad_idx, $lex_list ) = ( {}, [], [], [] );
    my $cxt = Language::P::Intermediate::Code->new
                  ( { type     => CODE_MAIN,
                      name     => undef,
                      outer    => undef,
                      lexicals => $lex_list,
                      } );
    $self->_lexicals( {} );
    $self->_lexicals->{$cxt} = { map     => $lex,
                                 lex_idx => $lex_idx,
                                 pad_idx => $pad_idx,
                                 };
    while( my( $name, $index ) = each %$indices ) {
        my $lexical = $lexicals->names->{$name};
        $lex->{$lexical} = $pad_idx->[$index] =
          Language::P::Intermediate::LexicalInfo->new
              ( { index       => $index,
                  outer_index => -1,
                  name        => $lexical->name,
                  sigil       => $lexical->sigil,
                  symbol_name => $lexical->symbol_name,
                  level       => 0,
                  in_pad      => 1,
                  } );
        push @$lex_list, $pad_idx->[$index];
    }

    return $cxt;
}

sub generate_regex {
    my( $self, $regex ) = @_;

    $self->_current_subroutine( undef );
    _generate_regex( $self, $regex, undef );
}

sub _generate_regex {
    my( $self, $regex, $outer ) = @_;

    $self->_code_segments( [] );
    $self->_group_count( 0 );
    $self->_pos_count( 0 );
    $self->_label_count( 0 );
    $self->_temporary_count( 0 );
    $self->_local_count( 0 );

    push @{$self->_code_segments},
         Language::P::Intermediate::Code->new
             ( { type         => CODE_REGEX,
                 basic_blocks => [],
                 regex_string => $regex->original,
                 outer        => $outer,
                 name         => undef,
                 } );
    push @{$outer->inner}, $self->_code_segments->[-1] if $outer;

    _add_blocks $self, _new_block( $self );
    _add_bytecode $self, opcode_n( OP_RX_START_MATCH );

    foreach my $e ( @{$regex->components} ) {
        $self->dispatch_regex( $e );
    }

    _add_bytecode $self,
        opcode_nm( OP_RX_ACCEPT, groups => $self->_group_count );

    die "Flag o not supported"
      if $regex->flags & FLAG_RX_ONCE;

    return $self->_code_segments;
}

sub generate_use {
    my( $self, $tree ) = @_;

    my $context = Language::P::ParseTree::PropagateContext->new;
    $context->visit( $tree, CXT_VOID );
    $self->_current_subroutine( undef );

    $self->_code_segments( [] );
    $self->_current_basic_block( undef );
    $self->_current_block( undef );
    $self->_current_lexical_state( undef );
    $self->_stack( [] );
    $self->_label_count( 0 );
    $self->_temporary_count( 0 );
    $self->_local_count( 0 );
    $self->_in_args_map( {} );

    my $head = $self->_new_block;
    my $empty = $self->_new_block;

    push @{$self->_code_segments},
         Language::P::Intermediate::Code->new
             ( { type         => CODE_SUB,
                 name         => 'BEGIN',
                 basic_blocks => [],
                 outer        => undef,
                 lexicals     => [],
                 prototype    => undef,
                 } );
    $self->_lexicals->{$self->_code_segments->[-1]}{max_stack} = 1;

    _add_blocks $self, $head;
    $self->push_block( SCOPE_SUB|SCOPE_MAIN, $tree->pos_s, $tree->pos_e );

    _lexical_state( $self, $tree->lexical_state );

    my $body = $self->_new_block;
    my $return = $self->_new_block;

    # check the Perl version
    if( $tree->version && !$tree->package ) {
        # compare version
        my $reqver  = opcode_nm( OP_CONSTANT_FLOAT, value => $tree->version );
        my $perlver = opcode_npm( OP_GLOBAL, $tree->pos,
                                  name    => ']',
                                  slot    => VALUE_SCALAR,
                                  context => CXT_SCALAR,
                                  );
        _add_jump $self,
            opcode_nam( OP_JUMP_IF_F_LT,
                        [ $reqver, $perlver ],
                        true  => $return,
                        false => $body ),
            $return, $body;

        # TODO use version objects
        # Perl v6.0.0 required--this is only v5.10.1, stopped
        my $die_string =
            opcode_nam( OP_MAKE_ARRAY,
                        [ opcode_nm( OP_FRESH_STRING, value => 'Perl ' ),
                          opcode_nm( OP_CONSTANT_FLOAT, value => $tree->version ),
                          opcode_nm( OP_CONSTANT_STRING, value => ' required--this is only ' ),
                          opcode_nm( OP_GLOBAL, name => ']', slot => VALUE_SCALAR, context => CXT_SCALAR ),
                          opcode_nm( OP_CONSTANT_STRING, value => ', stopped' ),
                          ],
                         context => CXT_LIST );

        _add_blocks $self, $body;
        _add_value $self,
            opcode_npam( OP_DIE, $tree->pos, [ $die_string ],
                         context => CXT_VOID );
        _pop( $self );
        _add_jump $self,
            opcode_nm( OP_JUMP, to => $return ),
            $return;

        # return
        _add_blocks $self, $return;
        $self->pop_block;
        _add_bytecode $self, opcode_n( OP_END );

        return $self->_code_segments;
    }

    ( my $file = $tree->package ) =~ s{::}{/}g;
    _add_value $self,
        opcode_npam( OP_REQUIRE_FILE, $tree->pos,
                     [ opcode_nm( OP_CONSTANT_STRING, value => "$file.pm" ) ],
                     context => CXT_VOID );
    _pop( $self );

    # TODO check version

    # always evaluate arguments, even if no import/unimport is present
    _add_value $self,
        opcode_nm( OP_CONSTANT_STRING, value => $tree->package );
    if( $tree->import ) {
        foreach my $arg ( @{$tree->import} ) {
            $self->dispatch( $arg );
        }
        _add_value $self,
            opcode_nam( OP_MAKE_ARRAY,
                        _get_stack( $self, scalar( @{$tree->import} ) + 1 ),
                        context   => CXT_LIST );
    } else {
        _add_value $self,
            opcode_nam( OP_MAKE_ARRAY,
                        _get_stack( $self, 1 ),
                        context   => CXT_LIST );
    }

    _add_value $self,
        opcode_npam( OP_FIND_METHOD, $tree->pos,
                     [ opcode_nm( OP_CONSTANT_STRING,
                                  value => $tree->package ) ],
                     context => CXT_SCALAR,
                     method => $tree->is_no ? 'unimport' : 'import' );
    _dump_out_stack( $self );
    _dup( $self );
    _add_jump $self,
        opcode_nam( OP_JUMP_IF_NULL,
                    _get_stack( $self, 1 ),
                    true  => $empty,
                    false => $body ),
        $empty, $body;

    # empty block, for SSA conversion
    _add_blocks $self, $empty;
    _pop( $self ); # pop undef value and arguments
    _pop( $self );
    _add_jump $self,
        opcode_nm( OP_JUMP, to => $return ),
        $return;

    # call the import method
    _add_blocks $self, $body;

    _add_value $self,
        opcode_npam( OP_CALL, $tree->pos,
                     _get_stack( $self, 2 ),
                     context => CXT_VOID );
    _pop( $self );
    _add_jump $self,
        opcode_nm( OP_JUMP, to => $return ),
        $return;

    # return
    _add_blocks $self, $return;
    $self->pop_block;
    _add_bytecode $self, opcode_n( OP_END );

    return $self->_code_segments;
}

sub generate_subroutine {
    my( $self, $tree, $outer ) = @_;

    my $context = Language::P::ParseTree::PropagateContext->new;
    $context->visit( $tree, CXT_VOID );

    _generate_bytecode( $self, 1, $tree->name, $tree->prototype,
                        $outer || $self->_main, $tree->lines,
                        $tree->pos_s, $tree->pos_e );
}

sub generate_bytecode {
    my( $self, $statements, $outer ) = @_;

    my $context = Language::P::ParseTree::PropagateContext->new;
    foreach my $tree ( @$statements ) {
        $context->visit( $tree, CXT_VOID );
    }
    my $pos_s = @$statements ? $statements->[0]->pos_s : undef;
    my $pos_e = @$statements ? $statements->[-1]->pos_e : undef;

    _generate_bytecode( $self, 0, undef, undef, $outer, $statements,
                        $pos_s, $pos_e );
}

sub _generate_bytecode {
    my( $self, $is_sub, $name, $prototype, $outer, $statements,
        $pos_s, $pos_e ) = @_;

    $self->_code_segments( [] );
    $self->_current_basic_block( undef );
    $self->_current_block( undef );
    $self->_current_lexical_state( undef );
    $self->_stack( [] );
    $self->_label_count( 0 );
    $self->_temporary_count( 0 );
    $self->_local_count( 0 );
    $self->_in_args_map( {} );

    if( !$is_sub && $self->_main ) {
        push @{$self->_code_segments}, $self->_main;
        $self->_main( undef );
    } else {
        my $flags = $is_sub ? CODE_SUB : CODE_MAIN;
        # constant sub optimization
        if(    $is_sub
            && $prototype && $prototype->[1] == 0 && $prototype->[2] == 0
            && @$statements == 2 ) {
            # first statement is a LexicalState, second an (implicit) return
            my $value = $statements->[1]->arguments->[0];

            if( $value->is_constant ) {
                $flags |= CODE_CONSTANT;
            } elsif(    $value->isa( 'Language::P::ParseTree::LexicalSymbol' )
                     && $outer ) {
                my $code_from = _uplevel( $outer, $value->level - 1 );

                $flags |= CODE_CONSTANT_PROTOTYPE unless $code_from->is_main;
            }
        }

        push @{$self->_code_segments},
             Language::P::Intermediate::Code->new
                 ( { type         => $flags,
                     name         => $name,
                     basic_blocks => [],
                     outer        => $outer,
                     lexicals     => [],
                     prototype    => $prototype,
                     } );
        $self->_lexicals->{$self->_code_segments->[-1]}{max_stack} = $is_sub ? 1 : 0;
    }
    push @{$outer->inner}, $self->_code_segments->[-1] if $outer;
    $self->_current_subroutine( $self->_code_segments->[-1] );

    _add_blocks $self, _new_block( $self );
    my $is_eval = $self->_code_segments->[-1]->is_eval;
    my $block_flags =   ( $is_sub  ? SCOPE_SUB : 0 )
                      | ( $is_eval ? SCOPE_EVAL : 0 )
                      |              SCOPE_MAIN;

    $self->push_block( 0, undef, undef );
    $self->push_block( $block_flags, $pos_s, $pos_e );

    if( !$is_sub && !$is_eval ) {
        _add_bytecode $self,
            opcode_nm( OP_LEXICAL_STATE_SET,  index => 0 );
    }

    # clear $@ when entering eval scope
    if( $is_eval ) {
        _add_bytecode $self,
            opcode_nam( OP_UNDEF,
                        [ opcode_nm( OP_GLOBAL,
                                     name    => '@',
                                     slot    => VALUE_SCALAR,
                                     context => CXT_SCALAR ) ] );
    }

    foreach my $tree ( @$statements ) {
        $self->dispatch( $tree );
        _discard_if_void( $self, $tree );
    }

    _dump_out_stack( $self );

    # clear $@ when exiting eval scope
    if( $is_eval ) {
        _add_bytecode $self,
            opcode_nam( OP_UNDEF,
                        [ opcode_nm( OP_GLOBAL,
                                     name    => '@',
                                     slot    => VALUE_SCALAR,
                                     context => CXT_SCALAR ) ] );
    }

    $self->pop_block;

    if( @{$self->_current_basic_block->bytecode} != 0 ) {
        my $end = _new_block( $self );
        _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;
        _add_blocks $self, $end;
    }
    _add_bytecode $self, opcode_n( OP_END );

    $self->pop_block;

    # remove edges from nodes with multiple successors to nodes
    # with multiple predecessors
    _check_split_edges( $self, $_ )
        foreach @{$self->_code_segments->[0]->basic_blocks};

    if( $self->_options->{'dump-ir'} ) {
        ( my $outfile = $self->file_name ) =~ s/(\.\w+)?$/.ir/;
        open my $ir_dump, '>', $outfile || die "Can't open '$outfile': $!";

        foreach my $cs ( @{$self->_code_segments} ) {
            $cs->find_alive_blocks;
            foreach my $bb ( @{$cs->basic_blocks} ) {
                foreach my $ins ( @{$bb->bytecode} ) {
                    print $ir_dump $ins->as_string( \%NUMBER_TO_NAME );
                }
            }
        }
    }

    return $self->_code_segments;
}

my %dispatch =
  ( 'Language::P::ParseTree::FunctionCall'           => '_function_call',
    'Language::P::ParseTree::MethodCall'             => '_method_call',
    'Language::P::ParseTree::Builtin'                => '_builtin',
    'Language::P::ParseTree::Overridable'            => '_builtin',
    'Language::P::ParseTree::BuiltinIndirect'        => '_indirect',
    'Language::P::ParseTree::UnOp'                   => '_unary_op',
    'Language::P::ParseTree::Local'                  => '_local',
    'Language::P::ParseTree::BinOp'                  => '_binary_op',
    'Language::P::ParseTree::Constant'               => '_constant',
    'Language::P::ParseTree::Symbol'                 => '_symbol',
    'Language::P::ParseTree::LexicalDeclaration'     => '_lexical_declaration',
    'Language::P::ParseTree::LexicalSymbol'          => '_lexical_symbol',
    'Language::P::ParseTree::List'                   => '_list',
    'Language::P::ParseTree::Conditional'            => '_cond',
    'Language::P::ParseTree::ConditionalLoop'        => '_cond_loop',
    'Language::P::ParseTree::For'                    => '_for',
    'Language::P::ParseTree::Foreach'                => '_foreach',
    'Language::P::ParseTree::Ternary'                => '_ternary',
    'Language::P::ParseTree::Block'                  => '_block',
    'Language::P::ParseTree::BareBlock'              => '_bare_block',
    'Language::P::ParseTree::NamedSubroutine'        => '_subroutine',
    'Language::P::ParseTree::SubroutineDeclaration'  => '_subroutine_decl',
    'Language::P::ParseTree::AnonymousSubroutine'    => '_anon_subroutine',
    'Language::P::ParseTree::Use'                    => '_use',
    'Language::P::ParseTree::QuotedString'           => '_quoted_string',
    'Language::P::ParseTree::Subscript'              => '_subscript',
    'Language::P::ParseTree::Slice'                  => '_slice',
    'Language::P::ParseTree::Jump'                   => '_jump',
    'Language::P::ParseTree::Pattern'                => '_pattern',
    'Language::P::ParseTree::InterpolatedPattern'    => '_interpolated_pattern',
    'Language::P::ParseTree::Parentheses'            => '_parentheses',
    'Language::P::ParseTree::ReferenceConstructor'   => '_ref_constructor',
    'Language::P::ParseTree::LexicalState'           => '_lexical_state',
    );

my %dispatch_cond =
  ( 'Language::P::ParseTree::BinOp'          => '_binary_op_cond',
    'DEFAULT'                                => '_anything_cond',
    );

my %dispatch_regex =
  ( 'Language::P::ParseTree::RXQuantifier'     => '_regex_quantifier',
    'Language::P::ParseTree::RXGroup'          => '_regex_group',
    'Language::P::ParseTree::RXConstant'       => '_regex_exact',
    'Language::P::ParseTree::RXAlternation'    => '_regex_alternate',
    'Language::P::ParseTree::RXAssertion'      => '_regex_assertion',
    'Language::P::ParseTree::RXAssertionGroup' => '_regex_assertion_group',
    'Language::P::ParseTree::RXClass'          => '_regex_class',
    'Language::P::ParseTree::RXSpecialClass'   => '_regex_special_class',
    );

sub dispatch {
    my( $self, $tree, @args ) = @_;

    return $self->visit_map( \%dispatch, $tree, @args );
}

sub dispatch_cond {
    my( $self, $tree, $true, $false ) = @_;

    return $self->visit_map( \%dispatch_cond, $tree, $true, $false );
}

sub dispatch_regex {
    my( $self, $tree, $true, $false ) = @_;

    return $self->visit_map( \%dispatch_regex, $tree, $true, $false );
}

my %conditionals =
  ( OP_NUM_LT() => OP_JUMP_IF_F_LT,
    OP_STR_LT() => OP_JUMP_IF_S_LT,
    OP_NUM_GT() => OP_JUMP_IF_F_GT,
    OP_STR_GT() => OP_JUMP_IF_S_GT,
    OP_NUM_LE() => OP_JUMP_IF_F_LE,
    OP_STR_LE() => OP_JUMP_IF_S_LE,
    OP_NUM_GE() => OP_JUMP_IF_F_GE,
    OP_STR_GE() => OP_JUMP_IF_S_GE,
    OP_NUM_EQ() => OP_JUMP_IF_F_EQ,
    OP_STR_EQ() => OP_JUMP_IF_S_EQ,
    OP_NUM_NE() => OP_JUMP_IF_F_NE,
    OP_STR_NE() => OP_JUMP_IF_S_NE,
    );

sub _lexical_state {
    my( $self, $tree ) = @_;
    my $scope_id = $self->_current_block->id;
    my $state_id = @{$self->_code_segments->[0]->lexical_states};

    push @{$self->_code_segments->[0]->lexical_states},
         Language::P::Intermediate::LexicalState->new
             ( { scope    => $scope_id,
                 package  => $tree->package,
                 hints    => $tree->hints,
                 warnings => $tree->warnings,
                 } );
    $self->_current_lexical_state( $state_id );
    $self->_code_segments->[0]->scopes->[$scope_id]->set_flags( $self->_code_segments->[0]->scopes->[$scope_id]->flags | SCOPE_LEX_STATE );

    # avoid generating a new basic block if the current basic block only
    # contains a label
    my $bb = $self->_current_basic_block;
    if( @{$bb->bytecode} == 0 ) {
        # TODO emit _save at block start
        _add_bytecode $self,
            opcode_nm( OP_LEXICAL_STATE_SET,  index => $state_id );

        return;
    }

    my $block = _new_block( $self );
    _add_jump $self, opcode_nm( OP_JUMP, to => $block ), $block;
    _add_blocks $self, $block;
    # TODO emit _save at block start
    _add_bytecode $self,
        opcode_nm( OP_LEXICAL_STATE_SET,  index => $state_id );
}

sub _indirect {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    if( $tree->function == OP_MAP ) {
        _map( $self, $tree );
        return;
    } elsif( $tree->function == OP_GREP ) {
        _grep( $self, $tree );
        return;
    } elsif( $tree->function == OP_SORT ) {
        _sort( $self, $tree );
        return;
    }

    if( $tree->indirect ) {
        $self->dispatch( $tree->indirect );
    } else {
        _add_value $self,
            opcode_npm( OP_GLOBAL, $tree->pos,
                        name    => 'STDOUT',
                        slot    => VALUE_HANDLE,
                        context => CXT_SCALAR,
                        );
    }

    foreach my $arg ( @{$tree->arguments} ) {
        $self->dispatch( $arg );
    }

    my $args = _get_stack( $self, scalar @{$tree->arguments} );
    _add_value $self,
        opcode_npam( $tree->function, $tree->pos,
                     [ @{_get_stack( $self, 1 )},
                       opcode_nam( OP_MAKE_ARRAY,
                                   $args,
                                   context   => CXT_LIST ) ],
                     context   => _context( $tree ) );
}

sub _builtin {
    my( $self, $tree ) = @_;
    my $op_flags = $OP_ATTRIBUTES{$tree->function}->{flags};

    if( $tree->function == OP_UNDEF ) {
        _emit_label( $self, $tree );
        if( $tree->arguments ) {
            $self->dispatch( $tree->arguments->[0] );
            _add_bytecode $self,
                opcode_npam( OP_UNDEF, $tree->pos,
                             _get_stack( $self, 1 ) );
        }
        _add_value $self, opcode_n( OP_CONSTANT_UNDEF );
    } elsif(    $tree->function == OP_EXISTS
             && $tree->arguments->[0]->isa( 'Language::P::ParseTree::Subscript' ) ) {
        _emit_label( $self, $tree );

        my $arg = $tree->arguments->[0];

        $self->dispatch( $arg->subscript );
        $self->dispatch( $arg->subscripted );

        _add_value $self,
            opcode_npam( $arg->type == VALUE_ARRAY ? OP_VIVIFY_ARRAY :
                                                     OP_VIVIFY_HASH,
                         $tree->pos, _get_stack( $self, 1 ),
                         context => CXT_SCALAR )
              if $arg->reference;
        _add_value $self,
            opcode_npam( $arg->type == VALUE_ARRAY ? OP_EXISTS_ARRAY :
                                                     OP_EXISTS_HASH,
                         $tree->pos, _get_stack( $self, 2 ),
                         context => _context( $tree ) );
    } elsif( $tree->function == OP_DELETE ) {
        _emit_label( $self, $tree );

        my $arg = $tree->arguments->[0];

        $self->dispatch( $arg->subscript );
        $self->dispatch( $arg->subscripted );

        _add_value $self,
            opcode_npam( $arg->type == VALUE_ARRAY ? OP_VIVIFY_ARRAY :
                                                     OP_VIVIFY_HASH,
                         $tree->pos, _get_stack( $self, 1 ),
                         context => CXT_SCALAR )
              if $arg->reference;
        if( $tree->arguments->[0]->isa( 'Language::P::ParseTree::Subscript' ) ) {
            # element
            _add_value $self,
                opcode_npam( $arg->type == VALUE_ARRAY ? OP_DELETE_ARRAY :
                                                         OP_DELETE_HASH,
                             $tree->pos, _get_stack( $self, 2 ),
                             context => _context( $tree ) );
        } else {
            # slice
            _add_value $self,
                opcode_npam( $arg->type == VALUE_ARRAY ? OP_DELETE_ARRAY_SLICE :
                                                         OP_DELETE_HASH_SLICE,
                             $tree->pos, _get_stack( $self, 2 ),
                             context => _context( $tree ) );
        }
    } elsif( $op_flags & Language::P::Opcodes::FLAG_UNARY ) {
        _emit_label( $self, $tree );

        my $count = scalar @{$tree->arguments || []};
        foreach my $arg ( @{$tree->arguments || []} ) {
            $self->dispatch( $arg );
        }

        if( $tree->function == OP_EVAL ) {
            my $plex = $tree->get_attribute( 'lexicals' );
            my %lex;
            while( my( $n, $l ) = each %$plex ) {
                $lex{$n} = _allocate_lexical( $self, $self->_code_segments->[0],
                                              $l, 1 )->index;
            }
            my $env = $tree->get_attribute( 'environment' );
            _add_value $self,
                opcode_npam( $tree->function, $tree->pos,
                             _get_stack( $self, 1 ),
                             context  => _context( $tree ),
                             hints    => $env->{hints},
                             warnings => $env->{warnings},
                             package  => $env->{package},
                             lexicals => \%lex,
                             globals  => $tree->get_attribute( 'globals' ) );
        } elsif( $op_flags & Language::P::Opcodes::FLAG_VARIADIC ) {
            _add_value $self,
                opcode_npam( $tree->function, $tree->pos,
                             _get_stack( $self, $count ),
                             context   => _context( $tree ) );
        } elsif( $tree->function == OP_DYNAMIC_GOTO ) {
            _return_like( $self, $tree );
        } else {
            _add_value $self,
                opcode_npam( $tree->function, $tree->pos,
                             _get_stack( $self, $count ),
                             context => _context( $tree ) );
        }
    } else {
        return _function_call( $self, $tree );
    }
}

sub _return_like {
    my( $self, $tree ) = @_;
    my $attrs = $OP_ATTRIBUTES{$tree->function};
    my $stack_count = @{$self->_stack};

    my $block = $self->_current_block;
    while( $block ) {
        _exit_scope( $self, $block );
        last if $block->flags & CODE_MAIN;
        $block = _outer_scope( $self, $block )
    }

    my $stack = _get_stack( $self, 1 );

    _discard_stack( $self );
    _add_bytecode $self,
        opcode_npam( $tree->function, $tree->pos, $stack,
                     context => _context( $tree ) );

    # discard the code emitted after a return since it is unreachable
    $self->_stack( _fake_stack( $stack_count ) );
    _add_blocks $self, _new_fake_block( $self );
}

sub _function_call {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $is_func = ref( $tree->function );
    my $proto = $tree->parsing_prototype;
    my $i = 0;
    my $argcount = 0;
    foreach my $arg ( @{$tree->arguments || []} ) {
        $self->dispatch( $arg );
        if(    $i + 3 <= $#$proto
            && ( $proto->[$i + 3] & PROTO_REFERENCE ) ) {
            if( $is_func ) {
                _add_value $self,
                    opcode_npam( OP_REFERENCE, $arg->pos,
                                 _get_stack( $self, 1 ) );
            } else {
                --$argcount;
            }
        }
        ++$argcount;
        ++$i;
    }

    if( $argcount == 1 && $tree->function == OP_RETURN ) {
        _unary_list( $self, _get_stack( $self, 1 ) );
    } else {
        _add_value $self,
            opcode_nam( $tree->function == OP_RETURN ? OP_MAKE_LIST : OP_MAKE_ARRAY,
                        _get_stack( $self, $argcount ),
                        context => CXT_LIST );
    }

    if( $is_func ) {
        $self->dispatch( $tree->function );
        _add_value $self,
            opcode_npam( OP_CALL, $tree->pos,
                         _get_stack( $self, 2 ),
                         context => _context( $tree ) );
    } elsif( $tree->function == OP_RETURN ) {
        _return_like( $self, $tree );
    } else {
        my $attrs = $OP_ATTRIBUTES{$tree->function};

        _add_value $self,
            opcode_npam( $tree->function, $tree->pos,
                         _get_stack( $self, $attrs->{in_args} ),
                         context => _context( $tree ) );
    }
}

sub _method_call {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    $self->dispatch( $tree->method )
        if $tree->indirect;
    $self->dispatch( $tree->invocant );

    my $args = $tree->arguments || [];
    foreach my $arg ( @$args ) {
        $self->dispatch( $arg );
    }

    my $arglist = opcode_nam( OP_MAKE_ARRAY,
                              _get_stack( $self, 1 + scalar @$args ),
                              context => CXT_LIST );

    if( $tree->indirect ) {
        my $indirect = _get_stack( $self, 1 );
        _add_value $self,
            opcode_npam( OP_CALL_METHOD_INDIRECT, $tree->pos,
                         [ $indirect->[0], $arglist ],
                         context  => _context( $tree ) );
    } else {
        _add_value $self,
            opcode_npam( OP_CALL_METHOD, $tree->pos, [ $arglist ],
                         context  => _context( $tree ),
                         method   => $tree->method );
    }
}

sub _unary_list {
    my( $self, $arg ) = @_;
    my $opn = $arg->[0]->opcode_n;

    if( $opn == OP_MAKE_LIST ) {
        _add_value( $self, $arg->[0] );
    } else {
        _add_value $self,
            opcode_nam( OP_MAKE_LIST, $arg,
                        context => CXT_LIST );
    }
}

sub _list {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    foreach my $arg ( @{$tree->expressions} ) {
        $self->dispatch( $arg );
    }

    _add_value $self,
        opcode_nam( OP_MAKE_LIST,
                    _get_stack( $self, scalar @{$tree->expressions} ),
                    context   => _context_lvalue( $tree ) );
}

sub _unary_op {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    $self->dispatch( $tree->left );

    my $op = $tree->op;
    return if $op == OP_PLUS;
    if( $tree->get_attribute( 'context' ) & CXT_VIVIFY ) {
        if( $op == OP_DEREFERENCE_SCALAR ) {
            $op = OP_VIVIFY_SCALAR;
        } elsif( $op == OP_DEREFERENCE_ARRAY ) {
            $op = OP_VIVIFY_ARRAY;
        } elsif( $op == OP_DEREFERENCE_HASH ) {
            $op = OP_VIVIFY_HASH;
        }
    }

    _add_value $self,
        opcode_npam( $op, $tree->pos,
                     _get_stack( $self, 1 ),
                     context   => _context_lvalue( $tree ) );
}

sub _local {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $left = $tree->left;

    # TODO to work as in Perl, it needs to push the local() down the
    #      expression tree, i.e.
    #      local ( $a ? $b : $c ) => $a ? local $b : local $c
    if( $left->isa( 'Language::P::ParseTree::Subscript' ) ) {
        my $index = $self->{_temporary_count}++;
        my $op_save = $left->type == VALUE_ARRAY ? OP_LOCALIZE_ARRAY_ELEMENT :
                                                   OP_LOCALIZE_HASH_ELEMENT;
        my $op_rest = $left->type == VALUE_ARRAY ? OP_RESTORE_ARRAY_ELEMENT :
                                                   OP_RESTORE_HASH_ELEMENT;
        my $vivify = !$left->reference           ? 0 :
                     $left->type == VALUE_ARRAY  ? OP_VIVIFY_ARRAY :
                                                   OP_VIVIFY_HASH;

        $self->dispatch( $left->subscript );
        $self->dispatch( $left->subscripted );

        if( $vivify ) {
            _add_value $self,
                opcode_npam( $vivify, $tree->pos,
                             _get_stack( $self, 1 ),
                             context => CXT_SCALAR );
        }

        _add_value $self,
            opcode_npam( $op_save, $left->pos,
                         _get_stack( $self, 2 ),
                         index => $index );

        push @{$self->_current_block->bytecode},
             [ opcode_nm( $op_rest, index => $index ) ];
    } elsif( $left->isa( 'Language::P::ParseTree::Slice' ) ) {
        die;
    } elsif( $left->isa( 'Language::P::ParseTree::Symbol' ) ) {
        my $index = $self->{_temporary_count}++;
        _add_value $self,
            opcode_npm( OP_LOCALIZE_GLOB_SLOT, $tree->pos,
                        name  => $left->name,
                        slot  => $left->sigil,
                        index => $index );

        push @{$self->_current_block->bytecode},
             [ opcode_nm( OP_RESTORE_GLOB_SLOT,
                          name  => $left->name,
                          slot  => $left->sigil,
                          index => $index,
                          ),
               ];
    } else {
        die "Internal error, handle localized lvalue expressions";
    }
}

sub _parentheses {
    my( $self, $tree ) = @_;

    $self->dispatch( $tree->left );
}

sub _substitution {
    my( $self, $tree ) = @_;
    my $pat = $tree->pattern;
    if( $pat->isa( 'Language::P::ParseTree::Pattern' ) ) {
        _pattern( $self, $pat );
    } elsif( $pat->isa( 'Language::P::ParseTree::InterpolatedPattern' ) ) {
        _interpolated_pattern( $self, $pat );
    } else {
        die $pat;
    }

    my $stack = $self->_stack;
    my $current = $self->_current_basic_block;
    my $block = _new_block( $self );

    $self->_stack( [] );
    _add_blocks $self, $block;

    $self->push_block( SCOPE_VALUE, $tree->replacement->pos_s,
                       $tree->replacement->pos_e,
                       CXT_SCALAR );

    if( $tree->replacement->isa( 'Language::P::ParseTree::Block' ) ) {
        _emit_lexical_state( $self, $tree->replacement );
        $self->dispatch( $_ )
          foreach @{$tree->replacement->lines};
    } else {
        $self->dispatch( $tree->replacement );
    }

    _exit_scope( $self, $self->_current_block );
    $self->pop_block;

    # OP_STOP marks the end of a sequence of opcodes that are run in a
    # secondary run loop; it is currently used only for regex
    # substitutions; maybe can be removed
    _add_bytecode $self, opcode_nam( OP_STOP, _get_stack( $self, 1 ) );

    $self->_current_basic_block( $current );
    $self->_stack( $stack );

    return $block;
}

sub _binary_op {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    if(    $tree->op == OP_LOG_AND || $tree->op == OP_LOG_OR
        || $tree->op == OP_LOG_AND_ASSIGN || $tree->op == OP_LOG_OR_ASSIGN ) {
        $self->dispatch( $tree->left );

        my( $right, $end, $to_end ) = _new_blocks( $self, 3 );

        # jump to $end if evalutating right is not necessary
        _dump_out_stack( $self );
        _dup( $self );
        _add_jump $self,
            opcode_npam( OP_JUMP_IF_TRUE, $tree->pos,
                         _get_stack( $self, 1 ),
                         $tree->op == OP_LOG_AND || $tree->op == OP_LOG_AND_ASSIGN ?
                             ( true => $right,  false => $to_end ) :
                             ( true => $to_end, false => $right ) ),
             $right, $to_end;

        _add_blocks $self, $to_end;

        # the left-hand tree is always in scalar context (so it always
        # produces a value) and it needs to be discarded if the tree is in void
        # context
        _discard_value( $self )
            if _context( $tree ) == CXT_VOID;
        _add_jump_unoptimized $self, opcode_nm( OP_JUMP, to => $end ), $end;

        _add_blocks $self, $right;

        # evalutates right only if this is the correct return value
        if( $tree->op == OP_LOG_AND || $tree->op == OP_LOG_OR ) {
            _discard_value( $self )
        }
        $self->dispatch( $tree->right );
        if( $tree->op == OP_LOG_AND_ASSIGN || $tree->op == OP_LOG_OR_ASSIGN ) {
            _add_value $self,
                opcode_nam( OP_SWAP_ASSIGN,
                            _get_stack( $self, 2 ),
                            context => _context( $tree ) );
            _discard_value( $self )
                if _context( $tree ) == CXT_VOID;
        } elsif( _context( $tree ) == CXT_VOID && !$tree->right->always_void ) {
            _discard_value( $self );
        }
        _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;
        _add_blocks $self, $end;
    } elsif( $tree->op == OP_ASSIGN ) {
        $self->dispatch( $tree->right );
        $self->dispatch( $tree->left );

        if( $tree->left->lvalue_context != CXT_LIST ) {
            _add_value $self,
                opcode_npam( OP_ASSIGN, $tree->pos,
                             _get_stack( $self, 2 ),
                             context => _context( $tree ) );
        } else {
            _add_value $self,
                opcode_npam( OP_ASSIGN_LIST, $tree->pos,
                             _get_stack( $self, 2 ),
                             context => _context( $tree ) );
        }
    } elsif( $tree->op == OP_MATCH || $tree->op == OP_NOT_MATCH ) {
        # TODO maybe build a different parse tree?
        if( $tree->right->isa( 'Language::P::ParseTree::Transliteration' ) ) {
            $self->dispatch( $tree->left );
            _add_value $self,
                opcode_npam( OP_TRANSLITERATE, $tree->pos,
                             _get_stack( $self, 1 ),
                             context     => _context( $tree ),
                             match       => ( join '', @{$tree->right->match} ),
                             replacement => ( join '', @{$tree->right->replacement} ),
                             flags       => $tree->right->flags );

            if( $tree->op == OP_NOT_MATCH ) {
                _add_value $self,
                    opcode_npam( OP_LOG_NOT, $tree->pos,
                                 _get_stack( $self, 1 ),
                                 context   => _context( $tree ) );
            }

            return;
        }

        my $scope_id = $self->_current_block->id;

        unless( $self->_code_segments->[0]->scopes->[$scope_id]->flags & SCOPE_REGEX ) {
            $self->_code_segments->[0]->scopes->[$scope_id]->set_flags( $self->_code_segments->[0]->scopes->[$scope_id]->flags | SCOPE_REGEX );
            push @{$self->_current_block->bytecode},
                 [ opcode_nm( OP_RX_STATE_RESTORE, index => $scope_id ) ];
        }

        $self->dispatch( $tree->left );

        if( $tree->right->isa( 'Language::P::ParseTree::Substitution' ) ) {
            my $repl = _substitution( $self, $tree->right );
            my $flags = $tree->right->pattern->flags &
                        (FLAG_RX_GLOBAL|FLAG_RX_KEEP);

            _add_value $self,
                opcode_npam( OP_REPLACE, $tree->pos,
                             _get_stack( $self, 2 ),
                             context   => _context( $tree ),
                             index     => $scope_id,
                             flags     => $flags,
                             to        => $repl );

            $self->_current_basic_block->add_successor( $repl );

            return;
        }

        $self->dispatch( $tree->right );

        my $flags = $tree->right->flags &
                    (FLAG_RX_GLOBAL|FLAG_RX_KEEP);

        _add_value $self,
            opcode_npam( OP_MATCH, $tree->pos,
                         _get_stack( $self, 2 ),
                         context   => _context( $tree ),
                         flags     => $flags,
                         index     => $scope_id );
        # maybe perform the transformation during parsing, but remember
        # to correctly propagate context
        if( $tree->op == OP_NOT_MATCH ) {
            _add_value $self,
                opcode_npam( OP_LOG_NOT, $tree->pos,
                             _get_stack( $self, 1 ),
                             context   => _context( $tree ) );
        }
    } elsif( $tree->op == OP_REPEAT ) {
        my $op;
        $self->dispatch( $tree->left );
        if( $tree->left->isa( 'Language::P::ParseTree::Parentheses' ) ) {
            $op = OP_REPEAT_ARRAY;
            _unary_list( $self, _get_stack( $self, 1 ) );
        } else {
            $op = OP_REPEAT_SCALAR;
        }

        $self->dispatch( $tree->right );

        _add_value $self,
            opcode_npam( $op, $tree->pos,
                         _get_stack( $self, 2 ),
                         context   => _context( $tree ) );
    } else {
        $self->dispatch( $tree->left );
        $self->dispatch( $tree->right );

        _add_value $self,
            opcode_npam( $tree->op, $tree->pos,
                         _get_stack( $self, 2 ),
                         context => _context( $tree ) );
    }
}

sub _binary_op_cond {
    my( $self, $tree, $true, $false ) = @_;

    if( $tree->op == OP_LOG_AND || $tree->op == OP_LOG_OR ) {
        my $right = _new_block( $self );

        $self->dispatch_cond( $tree->left,
                              $tree->op == OP_LOG_AND ?
                                  ( $right, $false ) :
                                  ( $true,  $right ) );

        _add_blocks $self, $right;

        # evalutates right only if this is the correct return value
        $self->dispatch_cond( $tree->right, $true, $false );

        return;
    } elsif( !$conditionals{$tree->op} ) {
        _anything_cond( $self, $tree, $true, $false );

        return;
    }

    _emit_label( $self, $tree );
    $self->dispatch( $tree->left );
    $self->dispatch( $tree->right );

    _add_jump $self,
        opcode_npam( $conditionals{$tree->op}, $tree->pos,
                     _get_stack( $self, 2 ),
                     true => $true, false => $false ), $true, $false;
}

sub _anything_cond {
    my( $self, $tree, $true, $false ) = @_;

    $self->dispatch( $tree );

    _add_jump $self,
        opcode_npam( OP_JUMP_IF_TRUE, $tree->pos,
                     _get_stack( $self, 1 ),
                     true => $true, false => $false ), $true, $false;
}

sub _constant {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );
    my $v;

    if( $tree->is_number ) {
        if( $tree->flags & NUM_INTEGER ) {
            _add_value $self,
                 opcode_nm( OP_CONSTANT_INTEGER, value => $tree->value );
        } elsif( $tree->flags & NUM_FLOAT ) {
            _add_value $self,
                 opcode_nm( OP_CONSTANT_FLOAT, value => $tree->value );
        } elsif( $tree->flags & NUM_OCTAL ) {
            _add_value $self,
                 opcode_nm( OP_CONSTANT_INTEGER,
                            value => oct '0' . $tree->value );
        } elsif( $tree->flags & NUM_HEXADECIMAL ) {
            _add_value $self,
                 opcode_nm( OP_CONSTANT_INTEGER,
                            value => oct '0x' . $tree->value );
        } elsif( $tree->flags & NUM_BINARY ) {
            _add_value $self,
                 opcode_nm( OP_CONSTANT_INTEGER,
                            value => oct '0b' . $tree->value );
        } else {
            die "Unhandled flags value";
        }
    } elsif( $tree->is_string ) {
        _add_value $self,
             opcode_nm( OP_CONSTANT_STRING, value => $tree->value );
    } else {
        die "Neither number nor string";
    }
}

sub _symbol {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    _add_value $self,
        opcode_npm( OP_GLOBAL, $tree->pos,
                    name    => $tree->name,
                    slot    => $tree->sigil,
                    context => _context_lvalue( $tree ),
                    );
}

sub _lexical_symbol {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    _do_lexical_access( $self, $tree->declaration, $tree->level, 0 );
}

sub _lexical_declaration {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    _do_lexical_access( $self, $tree, 0, 1 );
}

sub _find_add_value {
    my( $self, $code, $lexical ) = @_;
    my $lex = $self->_lexicals->{$code}{map}{$lexical};

    return $lex->index
        if $lex && $lex->index >= 0;

    $lex->set_index( $self->_lexicals->{$code}{max_pad}++ );

    return $lex->index;
}

sub _uplevel {
    my( $code, $level ) = @_;

    $code = $code->outer foreach 1 .. $level;

    return $code;
}

sub _allocate_lexical {
    my( $self, $code, $lexical, $level ) = @_;
    my $lex_info = $self->_lexicals->{$code}{map}{$lexical};
    return $lex_info if $lex_info && $lex_info->index >= 0;

    $lex_info = $self->_lexicals->{$code}{map}{$lexical} =
      Language::P::Intermediate::LexicalInfo->new
          ( { level       => $level,
              name        => $lexical->name,
              sigil       => $lexical->sigil,
              symbol_name => $lexical->symbol_name,
              index       => -1,
              outer_index => -1,
              in_pad      => $lexical->closed_over ? 1 : 0,
              from_main   => 0,
              } );
    push @{$code->lexicals}, $lex_info;

    if(    $lexical->name eq '_'
        && $lexical->sigil == VALUE_ARRAY ) {
        $lex_info->set_index( 0 ); # arguments are always first
    } elsif( $lexical->closed_over ) {
        $level = $lex_info->level;
        if( $level ) {
            my $code_from = _uplevel( $code, $level );
            my $val = _allocate_lexical( $self, $code_from,
                                         $lexical, 0 )->index;
            if( $code_from->is_sub ) {
                my $outer = $code->outer;
                _allocate_lexical( $self, $outer, $lexical, $level - 1 );
                $lex_info->set_index( _find_add_value( $self, $code, $lexical ) );
                $lex_info->set_outer_index( _find_add_value( $self, $outer, $lexical ) );
            } else {
                $lex_info->set_index( _find_add_value( $self, $code, $lexical ) );
                $lex_info->set_outer_index( $val );
                $lex_info->set_from_main( 1 );
            }
        } else {
            $lex_info->set_index( _find_add_value( $self, $code, $lexical ) );
        }
    } else {
        $lex_info->set_index( $self->_lexicals->{$code}{max_stack}++ );
    }

    if( $lex_info->in_pad ) {
        $self->_lexicals->{$code}{pad_idx}[$lex_info->index] = $lex_info;
    } else {
        $self->_lexicals->{$code}{lex_idx}[$lex_info->index] = $lex_info;
    }

    return $lex_info;
}

sub _do_lexical_access {
    my( $self, $tree, $level, $is_decl ) = @_;

    # maybe do it while parsing, in _find_symbol/_process_lexical_declaration
    my $lex_info = $self->_lexicals->{$self->_code_segments->[0]}{map}{$tree};
    if( !$lex_info || $lex_info->index < 0 ) {
        $lex_info = _allocate_lexical( $self, $self->_code_segments->[0],
                                       $tree, $level );
    }

    _add_value $self,
        opcode_nm( $lex_info->in_pad ? OP_LEXICAL_PAD : OP_LEXICAL,
                   lexical_info => $lex_info,
                   );

    if( $is_decl ) {
        $lex_info->set_declaration( 1 );

        push @{$self->_current_block->bytecode},
             [ opcode_nm( $lex_info->in_pad ? OP_LEXICAL_PAD_CLEAR : OP_LEXICAL_CLEAR,
                          lexical_info => $lex_info,
                          ),
               ];
    }
}

sub _cond_loop {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $is_until = $tree->block_type eq 'until';
    my( $start_cond, $start_loop, $start_continue, $end_loop ) = _new_blocks( $self, 4 );
    $tree->set_attribute( 'lbl_next', $tree->continue ? $start_continue :
                                                        $start_cond );
    $tree->set_attribute( 'lbl_last', $end_loop );
    $tree->set_attribute( 'lbl_redo', $start_loop );

    _add_jump $self,
        opcode_nm( OP_JUMP, to => $start_cond ), $start_cond;
    _add_blocks $self, $start_cond;

    if( $tree->block->isa( 'Language::P::ParseTree::Block' ) ) {
        _start_bb( $self );
        $self->push_block( 0, $tree->pos_s, $tree->pos_e );
    }

    $self->dispatch_cond( $tree->condition,
                          $is_until ? ( $end_loop, $start_loop ) :
                                      ( $start_loop, $end_loop ) );

    _add_blocks $self, $start_loop;
    $self->dispatch( $tree->block );
    _discard_if_void( $self, $tree->block );

    if( $tree->continue ) {
        _add_jump $self,
            opcode_nm( OP_JUMP, to => $start_continue ), $start_continue;

        _add_blocks $self, $start_continue;
        $self->dispatch( $tree->continue );
    }

    _add_jump $self, opcode_nm( OP_JUMP, to => $start_cond ), $start_cond;
    _add_blocks $self, $end_loop;

    if( $tree->block->isa( 'Language::P::ParseTree::Block' ) ) {
        _exit_scope( $self, $self->_current_block );
        $self->pop_block;
        _start_bb( $self );
    }
}

sub _setup_list_iteration {
    my( $self, $tree, $iter_var, $list, $in_block ) = @_;
    my $is_lexical_declaration = $iter_var->isa( 'Language::P::ParseTree::LexicalDeclaration' );
    my $is_lexical = $is_lexical_declaration || $iter_var->isa( 'Language::P::ParseTree::LexicalSymbol' );

    my( $start_step, $start_loop, $start_continue, $exit_loop, $end_loop ) =
        _new_blocks( $self, 5 );

    if( $in_block ) {
        _start_bb( $self );
        $self->push_block( 0, $tree->pos_s, $tree->pos_e );
    }
    $self->dispatch( $list );
    _unary_list( $self, _get_stack( $self, 1 ) );

    my $iterator = $self->{_temporary_count}++;
    my( $glob );
    _add_bytecode $self,
        opcode_nam( OP_TEMPORARY_SET,
                    [ opcode_npam( OP_ITERATOR, $tree->pos,
                                   _get_stack( $self, 1 ) ) ],
                    index => $iterator,
                    slot  => VALUE_ITERATOR );

    if( $is_lexical_declaration ) {
        _allocate_lexical( $self, $self->_code_segments->[0], $iter_var, 0 );
    } elsif( $is_lexical ) {
        _allocate_lexical( $self, $self->_code_segments->[0],
                           $iter_var->declaration, $iter_var->level );
    }

    if( !$is_lexical ) {
        $glob = $self->{_temporary_count}++;
        my $slot = $self->{_temporary_count}++;

        _add_bytecode $self,
            opcode_nam( OP_TEMPORARY_SET,
                        [ opcode_nm( OP_GLOBAL,
                                     name    => $iter_var->name,
                                     slot    => VALUE_GLOB,
                                     context => CXT_SCALAR ) ],
                        index => $glob,
                        slot  => VALUE_GLOB );
        _add_value $self,
            opcode_npm( OP_LOCALIZE_GLOB_SLOT, $tree->pos,
                        name  => $iter_var->name,
                        slot  => VALUE_SCALAR,
                        index => $slot,
                        );
        _discard_value( $self );

        push @{$self->_current_block->bytecode},
             [ opcode_nm( OP_TEMPORARY_CLEAR,
                          index => $glob,
                          slot  => VALUE_GLOB ),
               opcode_npm( OP_RESTORE_GLOB_SLOT, $tree->pos,
                           name  => $iter_var->name,
                           slot  => VALUE_SCALAR,
                           index => $slot,
                           ),
               ];
    } elsif( !$is_lexical_declaration ) {
        my $slot = $self->{_temporary_count}++;
        my $lex_info = $self->_lexicals->{$self->_code_segments->[0]}{map}{$iter_var->declaration};
        my $in_pad = $lex_info->in_pad;

        _add_bytecode $self,
            opcode_nm( $in_pad ? OP_LOCALIZE_LEXICAL_PAD : OP_LOCALIZE_LEXICAL,
                       index        => $slot,
                       lexical_info => $lex_info,
                       );

        push @{$self->_current_block->bytecode},
             [ opcode_nm( $in_pad ? OP_RESTORE_LEXICAL_PAD : OP_RESTORE_LEXICAL,
                          index        => $slot,
                          lexical_info => $lex_info,
                          ),
               ];
    }

    _add_jump $self, opcode_nm( OP_JUMP, to => $start_step ), $start_step;
    _add_blocks $self, $start_step;

    _add_value $self,
        opcode_npam( OP_ITERATOR_NEXT, $tree->pos,
                     [ opcode_nm( OP_TEMPORARY,
                                  index => $iterator,
                                  slot  => VALUE_ITERATOR ) ] );
    _dump_out_stack( $self );
    _dup( $self );
    _add_jump $self,
        opcode_npam( OP_JUMP_IF_NULL, $tree->pos,
                     _get_stack( $self, 1 ),
                     true => $exit_loop, false => $start_loop ),
        $exit_loop, $start_loop;

    if( !$is_lexical ) {
        _add_blocks $self, $start_loop;
        my $scalar = _get_stack( $self, 1 );
        _add_bytecode $self,
            opcode_nam( OP_SWAP_GLOB_SLOT_SET,
                        [ $scalar->[0],
                          opcode_nm( OP_TEMPORARY,
                                     index => $glob,
                                     slot  => VALUE_GLOB ) ],
                        slot => VALUE_SCALAR );
    } else {
        _add_blocks $self, $start_loop;
        my $lex_info;
        if( $is_lexical_declaration ) {
            $lex_info = $self->_lexicals->{$self->_code_segments->[0]}{map}{$iter_var};
        } else {
            $lex_info = $self->_lexicals->{$self->_code_segments->[0]}{map}{$iter_var->declaration};
        }

        _add_bytecode $self,
            opcode_nam( $lex_info->in_pad ? OP_LEXICAL_PAD_SET : OP_LEXICAL_SET,
                        _get_stack( $self, 1 ),
                        lexical_info => $lex_info,
                        );
    }

    return ( $start_step, $start_loop, $start_continue, $exit_loop, $end_loop );
}

sub _end_list_iteration {
    my( $self, $tree, $enter_block, $start_step, $exit_loop, $end_loop ) = @_;

    _add_jump $self, opcode_nm( OP_JUMP, to => $start_step ), $start_step;
    _add_blocks $self, $exit_loop;
    _pop( $self );
    _add_jump $self, opcode_nm( OP_JUMP, to => $end_loop ), $end_loop;
    _add_blocks $self, $end_loop;

    if( $enter_block ) {
        _exit_scope( $self, $self->_current_block );
        $self->pop_block;
        _start_bb( $self );
    }
}

sub _foreach {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $iter_var = $tree->variable;
    my $enter_block = $tree->block->isa( 'Language::P::ParseTree::Block' );
    my( $start_step, $start_loop, $start_continue, $exit_loop, $end_loop ) =
        _setup_list_iteration( $self, $tree, $iter_var, $tree->expression,
                               $enter_block );

    $tree->set_attribute( 'lbl_next', $tree->continue ? $start_continue :
                                                        $start_step );
    $tree->set_attribute( 'lbl_last', $end_loop );
    $tree->set_attribute( 'lbl_redo', $start_loop );

    $self->dispatch( $tree->block );
    _discard_if_void( $self, $tree->block );

    if( $tree->continue ) {
        _add_jump $self,
            opcode_nm( OP_JUMP, to => $start_continue ), $start_continue;

        _add_blocks $self, $start_continue;
        $self->dispatch( $tree->continue );
    }

    _end_list_iteration( $self, $tree, $enter_block, $start_step,
                         $exit_loop, $end_loop );
}

sub _map {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $iter_var = Language::P::ParseTree::Symbol->new
                       ( { name  => '_',
                           sigil => VALUE_SCALAR,
                           } );
    my $expression = $tree->indirect || $tree->arguments->[0];
    my $st = $tree->indirect ? 0 : 1;
    my $en = $#{$tree->arguments};
    my $list = Language::P::ParseTree::List->new
                   ( { expressions => [ @{$tree->arguments}[ $st .. $en ] ],
                       } );
    $list->set_attribute( 'context', CXT_LIST );

    # result value
    my $result = $self->{_temporary_count}++;
    _add_bytecode $self,
        opcode_nam( OP_TEMPORARY_SET,
                    [ opcode_nam( OP_MAKE_LIST, [], context => CXT_LIST ) ],
                    index => $result, slot => VALUE_ARRAY );

    my( $start_step, $start_loop, $start_continue, $exit_loop, $end_loop ) =
        _setup_list_iteration( $self, $tree, $iter_var, $list, 0 );

    # call expresssion and add it to the result
    _add_value $self,
        opcode_nm( OP_TEMPORARY, index => $result, slot => VALUE_ARRAY );
    $self->dispatch( $expression );
    _add_bytecode $self,
        opcode_nam( OP_PUSH_ELEMENT, _get_stack( $self, 2 ) );

    _end_list_iteration( $self, $tree, 0, $start_step,
                         $exit_loop, $end_loop );

    # return the result
    _add_value $self,
        opcode_nm( OP_TEMPORARY, index => $result, slot => VALUE_ARRAY );
    _dump_out_stack( $self );
    _add_bytecode $self,
        opcode_nm( OP_TEMPORARY_CLEAR, index => $result, slot => VALUE_ARRAY );
}

sub _grep {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $iter_var = Language::P::ParseTree::Symbol->new
                       ( { name  => '_',
                           sigil => VALUE_SCALAR,
                           } );
    my $expression = $tree->indirect || $tree->arguments->[0];
    my $st = $tree->indirect ? 0 : 1;
    my $en = $#{$tree->arguments};
    my $list = Language::P::ParseTree::List->new
                   ( { expressions => [ @{$tree->arguments}[ $st .. $en ] ],
                       } );
    $list->set_attribute( 'context', CXT_LIST );

    # result value
    my $result = $self->{_temporary_count}++;
    _add_bytecode $self,
        opcode_nam( OP_TEMPORARY_SET,
                    [ opcode_nam( OP_MAKE_LIST, [], context => CXT_LIST ) ],
                    index => $result, slot => VALUE_ARRAY );

    my( $start_step, $start_loop, $start_continue, $exit_loop, $end_loop ) =
        _setup_list_iteration( $self, $tree, $iter_var, $list, 0 );

    # call expresssion and add it to the result
    $self->dispatch( $expression );

    my( $iftrue, $iffalse ) = _new_blocks( $self, 2 );
    _add_jump $self,
        opcode_nam( OP_JUMP_IF_TRUE,
                    _get_stack( $self, 1 ),
                    true => $iftrue, false => $iffalse ),
        $iftrue, $iffalse;
    _add_blocks $self, $iftrue;
    _add_bytecode $self,
        opcode_nam( OP_PUSH_ELEMENT,
                    [ opcode_nm( OP_TEMPORARY,
                                 index => $result,
                                 slot  => VALUE_ARRAY ),
                      opcode_nm( OP_GLOBAL,
                                 name    => '_',
                                 slot    => VALUE_SCALAR,
                                 context => CXT_SCALAR ) ],
                    );
    _add_jump $self,
        opcode_nm( OP_JUMP, to => $iffalse ),
        $iffalse;
    _add_blocks $self, $iffalse;

    _end_list_iteration( $self, $tree, 0, $start_step,
                         $exit_loop, $end_loop );

    # return the result
    _add_value $self,
        opcode_nm( OP_TEMPORARY, index => $result, slot => VALUE_ARRAY );
    _dump_out_stack( $self );
    _add_bytecode $self,
        opcode_nm( OP_TEMPORARY_CLEAR, index => $result, slot => VALUE_ARRAY );
}

sub _sort {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $list = Language::P::ParseTree::List->new
                   ( { expressions => $tree->arguments,
                       } );
    $list->set_attribute( 'context', CXT_LIST );
    $self->dispatch( $list );

    die 'Unsupported custom sort comparison' if $tree->indirect;
    _add_value $self,
        opcode_npam( OP_SORT, $tree->pos,
                     _get_stack( $self, 1 ),
                     context => _context( $tree ) );
}

sub _for {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my( $start_cond, $start_loop, $start_step, $end_loop ) = _new_blocks( $self, 4 );
    $tree->set_attribute( 'lbl_next', $start_step );
    $tree->set_attribute( 'lbl_last', $end_loop );
    $tree->set_attribute( 'lbl_redo', $start_loop );

    _start_bb( $self );
    $self->push_block( 0, $tree->pos_s, $tree->pos_e );

    if( $tree->initializer ) {
        $self->dispatch( $tree->initializer );
        _discard_if_void( $self, $tree->initializer );
    }

    _add_jump $self,
         opcode_nm( OP_JUMP, to => $start_cond ), $start_cond;
    _add_blocks $self, $start_cond;

    if( $tree->condition ) {
        $self->dispatch_cond( $tree->condition, $start_loop, $end_loop );
    } else {
        _add_jump $self,
            opcode_nm( OP_JUMP, to => $start_loop ), $start_loop;
    }

    _add_blocks $self, $start_loop;
    $self->dispatch( $tree->block );
    _discard_if_void( $self, $tree->block );

    _add_jump $self,
         opcode_nm( OP_JUMP, to => $start_step ), $start_step;

    _add_blocks $self, $start_step;

    if( $tree->step ) {
        $self->dispatch( $tree->step );
        _discard_if_void( $self, $tree->step );
    }

    _add_jump $self, opcode_nm( OP_JUMP, to => $start_cond ), $start_cond;

    _add_blocks $self, $end_loop;
    _exit_scope( $self, $self->_current_block );
    $self->pop_block;
    _start_bb( $self );
}

sub _cond {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $with_scope =    $tree->iffalse
                     || $tree->iftrues->[0]->block->isa( 'Language::P::ParseTree::Block' );

    my $last = _new_block( $self );
    if( $with_scope ) {
        _start_bb( $self );
        $self->push_block( 0, $tree->pos_s, $tree->pos_e );
    }

    my $next = _new_block( $self );
    _add_jump $self, opcode_nm( OP_JUMP, to => $next ), $next;

    foreach my $elsif ( @{$tree->iftrues} ) {
        my $is_unless = $elsif->block_type eq 'unless';
        my( $then_block, $next_next ) = _new_blocks( $self, 2 );
        _add_blocks $self, $next;
        $self->dispatch_cond( $elsif->condition,
                              $is_unless ? ( $next_next, $then_block ) :
                                           ( $then_block, $next_next ) );
        _add_blocks $self, $then_block;
        $self->dispatch( $elsif->block );
        _discard_if_void( $self, $elsif->block );

        _add_jump $self, opcode_nm( OP_JUMP, to => $last ), $last;
        $next = $next_next;
    }

    _add_blocks $self, $next;
    $self->dispatch( $tree->iffalse->block ) if $tree->iffalse;
    _add_jump $self, opcode_nm( OP_JUMP, to => $last ), $last;

    _add_blocks $self, $last;

    if( $with_scope ) {
        _exit_scope( $self, $self->_current_block );
        $self->pop_block;
        _start_bb( $self );
    }
}

sub _ternary {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my( $end, $true, $false ) = _new_blocks( $self, 3 );
    $self->dispatch_cond( $tree->condition, $true, $false );

    _add_blocks $self, $true;
    $self->dispatch( $tree->iftrue );
    _discard_value( $self )
        if    $self->is_stack
           && _context( $tree ) == CXT_VOID
           && !$tree->iftrue->always_void;
    _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;

    _add_blocks $self, $false;
    $self->dispatch( $tree->iffalse );
    _discard_value( $self )
        if    $self->is_stack
           && _context( $tree ) == CXT_VOID
           && !$tree->iffalse->always_void;
    _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;

    _add_blocks $self, $end;
}

sub _emit_lexical_state {
    my( $self, $tree ) = @_;

    if( $tree->get_attribute( 'lexical_state' ) ) {
        my $scope_id = $self->_current_block->id;
        my $lex_state = $self->_code_segments->[0]->scopes->[$scope_id]->lexical_state;

        _add_bytecode $self,
            opcode_nm( OP_LEXICAL_STATE_SAVE, index => $lex_state );
        push @{$self->_current_block->bytecode},
             [ opcode_nm( OP_LEXICAL_STATE_RESTORE, index => $lex_state ) ];
    }
}

sub _block {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    _start_bb( $self );
    my $is_eval = $tree->isa( 'Language::P::ParseTree::EvalBlock' );
    $self->push_block( $is_eval ? SCOPE_EVAL : 0, $tree->pos_s, $tree->pos_e,
                       $is_eval ? _context( $tree ) : 0 );
    _emit_lexical_state( $self, $tree );
    # clear $@ when entering eval scope
    if( $is_eval ) {
        _add_bytecode $self,
            opcode_nam( OP_UNDEF,
                        [ opcode_nm( OP_GLOBAL,
                                     name    => '@',
                                     slot    => VALUE_SCALAR,
                                     context => CXT_SCALAR ) ] );
    }

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
        _discard_if_void( $self, $line );
    }

    _exit_scope( $self, $self->_current_block );
    # clear $@ when exiting eval scope
    if( $is_eval ) {
        _leave_current_basic_block( $self );
        _add_bytecode $self,
            opcode_nam( OP_UNDEF,
                        [ opcode_nm( OP_GLOBAL,
                                     name    => '@',
                                     slot    => VALUE_SCALAR,
                                     context => CXT_SCALAR ) ] );
    }
    my $block = $self->pop_block;
    # emit landing point for eval
    if( $is_eval ) {
        my( $except, $resume ) = _new_blocks( $self, 2 );
        my $current = $self->_current_basic_block;

        $self->_code_segments->[0]->scopes->[$block->id]->set_exception( $except );

        # execution resumes here for both success and failure
        _add_jump $self, opcode_nm( OP_JUMP, to => $resume ), $resume;

        # landing point for exceptions
        _add_blocks $self, $except;
        if( !$self->is_stack && _context( $tree ) != CXT_VOID ) {
            my $stack = _create_in_stack( $self, $self->_in_args_map->{$current} );
            $stack->[-1] = opcode_n( OP_CONSTANT_UNDEF );
            $self->_stack( $stack );
        } elsif( _context( $tree ) != CXT_VOID ) {
            _add_value $self, opcode_n( OP_CONSTANT_UNDEF );
        }
        _add_jump $self, opcode_nm( OP_JUMP, to => $resume ), $resume;

        # add the resume block
        _add_blocks $self, $resume;
    }
}

sub _bare_block {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my( $start_loop, $start_continue, $end_loop ) = _new_blocks( $self, 3 );
    $tree->set_attribute( 'lbl_next', $end_loop );
    $tree->set_attribute( 'lbl_last', $end_loop );
    $tree->set_attribute( 'lbl_redo', $start_loop );

    _add_jump $self,
        opcode_nm( OP_JUMP, to => $start_loop ), $start_loop;
    _add_blocks $self, $start_loop;

    $self->push_block( 0, $tree->pos_s, $tree->pos_e );
    _emit_lexical_state( $self, $tree );

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
        _discard_if_void( $self, $line );
    }

    _exit_scope( $self, $self->_current_block );
    $self->pop_block;

    if( $tree->continue ) {
        _add_jump $self,
            opcode_nm( OP_JUMP, to => $start_continue ), $start_continue;

        _add_blocks $self, $start_continue;
        $self->dispatch( $tree->continue );
    }

    _add_jump $self,
        opcode_nm( OP_JUMP, to => $end_loop ), $end_loop;
    _add_blocks $self, $end_loop;
}

sub _subroutine_decl {
    my( $self, $tree ) = @_;

    # nothing to do
}

sub _anon_subroutine {
    my( $self, $tree ) = @_;
    my $sub = _subroutine( $self, $tree );

    _add_value $self,
        opcode_nam( OP_MAKE_CLOSURE,
                    [ opcode_nm( OP_CONSTANT_SUB, value => $sub ) ] );
}

sub _subroutine {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $generator = Language::P::Intermediate::Generator->new
                        ( { _options => { %{$self->{_options}},
                                          # performed by caller
                                          'dump-ir' => 0,
                                          },
                            _lexicals => $self->_lexicals,
                            is_stack => $self->is_stack,
                            } );
    my $code_segments =
      _generate_bytecode( $generator, 1, $tree->name, $tree->prototype,
                          $self->_code_segments->[0], $tree->lines );
    push @{$self->_code_segments}, @$code_segments;

    return $code_segments->[0];
}

sub _use {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $generator = Language::P::Intermediate::Generator->new
                        ( { _options => { %{$self->{_options}},
                                          # performed by caller
                                          'dump-ir' => 0,
                                          },
                            _lexicals => $self->_lexicals,
                            is_stack => $self->is_stack,
                            } );
    my $code_segments = $generator->generate_use( $tree );
    push @{$self->_code_segments}, @$code_segments;

    return $code_segments->[0];
}

sub _quoted_string {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    if( @{$tree->components} == 1 ) {
        my $c = $tree->components->[0];
        if(    ( $c->is_symbol && $c->sigil == VALUE_ARRAY )
            || (    $c->isa( 'Language::P::ParseTree::Dereference' )
                 && $c->op == OP_DEREFERENCE_ARRAY ) ) {
            _add_value $self,
                opcode_npm( OP_GLOBAL, $tree->pos,
                            name    => '"',
                            slot    => VALUE_SCALAR,
                            context => CXT_SCALAR );
            $self->dispatch( $c );
            _add_value $self,
                opcode_npam( OP_JOIN, $tree->pos,
                             [ opcode_nam( OP_MAKE_LIST,
                                           _get_stack( $self, 2 ),
                                           context => CXT_LIST ) ],
                             context => _context( $tree ) );
        } else {
            $self->dispatch( $c );
            _add_value $self,
                opcode_npam( OP_STRINGIFY, $tree->pos,
                             _get_stack( $self, 1 ),
                             context => _context( $tree ) );
        }

        return;
    }

    _add_value $self, opcode_nm( OP_FRESH_STRING, value => '' );
    for( my $i = 0; $i < @{$tree->components}; ++$i ) {
        my $c = $tree->components->[$i];
        if(    ( $c->is_symbol && $c->sigil == VALUE_ARRAY )
            || (    $c->isa( 'Language::P::ParseTree::Dereference' )
                 && $c->op == OP_DEREFERENCE_ARRAY ) ) {
            _add_value $self,
                opcode_npm( OP_GLOBAL, $tree->pos,
                            name    => '"',
                            slot    => VALUE_SCALAR,
                            context => CXT_SCALAR );
            $self->dispatch( $c );
            _add_value $self,
                opcode_npam( OP_JOIN, $tree->pos,
                             [ opcode_nam( OP_MAKE_LIST,
                                           _get_stack( $self, 2 ),
                                           context => CXT_LIST ) ],
                             context => _context( $tree ) );
        } else {
            $self->dispatch( $c );
        }

        _add_value $self,
            opcode_npam( OP_CONCATENATE_ASSIGN, $tree->pos,
                         _get_stack( $self, 2 ),
                         context => CXT_SCALAR );
    }
}

sub _subscript {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    $self->dispatch( $tree->subscript );
    $self->dispatch( $tree->subscripted );

    my $lvalue = $tree->get_attribute( 'context' ) & (CXT_LVALUE|CXT_VIVIFY);
    if( $tree->type == VALUE_ARRAY ) {
        _add_value $self, opcode_npam( OP_VIVIFY_ARRAY, $tree->pos,
                                       _get_stack( $self, 1 ),
                                       context   => CXT_SCALAR )
          if $tree->reference;
        _add_value $self, opcode_npam( OP_ARRAY_ELEMENT, $tree->pos,
                                       _get_stack( $self, 2 ),
                                       create    => $lvalue ? 1 : 0,
                                       context   => _context( $tree ) );
    } elsif( $tree->type == VALUE_HASH ) {
        _add_value $self, opcode_npam( OP_VIVIFY_HASH, $tree->pos,
                                       _get_stack( $self, 1 ),
                                       context   => CXT_SCALAR )
          if $tree->reference;
        _add_value $self, opcode_npam( OP_HASH_ELEMENT, $tree->pos,
                                       _get_stack( $self, 2 ),
                                       create    => $lvalue ? 1 : 0,
                                       context   => _context( $tree ) );
    } elsif( $tree->type == VALUE_GLOB ) {
        _add_value $self, opcode_npam( OP_DEREFERENCE_GLOB, $tree->pos,
                                       _get_stack( $self, 1 ),
                                       context   => CXT_SCALAR )
          if $tree->reference;
        _add_value $self, opcode_npam( OP_GLOB_ELEMENT, $tree->pos,
                                       _get_stack( $self, 2 ),
                                       create    => $lvalue ? 1 : 0,
                                       context   => _context( $tree ) );
    } else {
        die $tree->type;
    }
}

sub _slice {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    $self->dispatch( $tree->subscript );
    $self->dispatch( $tree->subscripted );

    my $lvalue = $tree->get_attribute( 'context' ) & (CXT_LVALUE|CXT_VIVIFY);
    if( $tree->type == VALUE_ARRAY ) {
        _add_value $self, opcode_npam( OP_VIVIFY_ARRAY, $tree->pos,
                                       _get_stack( $self, 1 ),
                                       context   => CXT_SCALAR )
          if $tree->reference;
        _add_value $self, opcode_npam( OP_ARRAY_SLICE, $tree->pos,
                                       _get_stack( $self, 2 ),
                                       create    => $lvalue ? 1 : 0,
                                       context   => _context( $tree ) );
    } elsif( $tree->type == VALUE_HASH ) {
        _add_value $self, opcode_npam( OP_VIVIFY_HASH, $tree->pos,
                                       _get_stack( $self, 1 ),
                                       context   => CXT_SCALAR )
          if $tree->reference;
        _add_value $self, opcode_npam( OP_HASH_SLICE, $tree->pos,
                                       _get_stack( $self, 2 ),
                                       create    => $lvalue ? 1 : 0,
                                       context   => _context( $tree ) );
    } elsif( $tree->type == VALUE_LIST ) {
        _add_value $self, opcode_npam( OP_LIST_SLICE, $tree->pos,
                                       _get_stack( $self, 2 ),
                                       context   => _context( $tree ) );
    } else {
        die $tree->type;
    }
}

sub _ref_constructor {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    # the empty list constructor can be optimized away when emitting
    if( $tree->expression ) {
        $self->dispatch( $tree->expression );
    } else {
        _add_value $self, opcode_nam( OP_MAKE_LIST, [], context => CXT_LIST );
    }

    if( $tree->type == VALUE_ARRAY ) {
        _add_value $self, opcode_npam( OP_ANONYMOUS_ARRAY, $tree->pos, _get_stack( $self, 1 ) );
    } elsif( $tree->type == VALUE_HASH ) {
        _add_value $self, opcode_npam( OP_ANONYMOUS_HASH, $tree->pos, _get_stack( $self, 1 ) );
    } else {
        die $tree->type;
    }
}

# find the node that is the target of a goto or the loop node that
# last/redo/next controls
sub _find_jump_target {
    my( $self, $node ) = @_;
    return $node->get_attribute( 'target' ) if $node->has_attribute( 'target' );
    return if $node->op == OP_GOTO;

    # search for the closest loop (for unlabeled jumps) or the closest
    # loop with matching label
    my $target_label = $node->left;
    while( $node ) {
        $node = $node->parent;
        last if $node->isa( 'Language::P::ParseTree::Subroutine' );
        next unless $node->is_loop;
        # found loop
        return $node if !$target_label;
        next unless $node->has_attribute( 'label' );
        return $node if $node->get_attribute( 'label' ) eq $target_label;
    }

    return;
}

# number of blocks to unwind when jumping out of a loop/nested scope
sub _unwind_level {
    my( $self, $node, $to_outer ) = @_;
    my $level = 0;

    while( $node && ( !$to_outer || $node != $to_outer ) ) {
        ++$level if    $node->isa( 'Language::P::ParseTree::Block' )
                    && !$node->isa( 'Language::P::ParseTree::BareBlock' );
        ++$level if $node->is_loop;
        $node = $node->parent;
    }

    return $level;
}

# find the common ancestor of two nodes (assuming they are in the same
# subroutine)
sub _find_ancestor {
    my( $self, $from, $to ) = @_;
    my %parents;

    for( my $node = $from; $node; $node = $node->parent ) {
        $parents{$node} = 1;
        last if $node->isa( 'Language::P::ParseTree::Subroutine' );
    }

    for( my $node = $to; $node; $node = $node->parent ) {
        return $node if $parents{$node};
        die "Can't happen" if $node->isa( 'Language::P::ParseTree::Subroutine' );
    }

    return;
}

sub _jump {
    my( $self, $tree ) = @_;
    my $target = _find_jump_target( $self, $tree );
    my $stack_count = @{$self->_stack};

    # discard temporaries present on the stack before jumping; it is a
    # no-op when the jump is a statement
    _discard_stack( $self );

    my $unwind_to = $tree->op == OP_GOTO ?
                        _find_ancestor( $self, $tree, $target ) :
                        $target;
    my $level = _unwind_level( $self, $tree, $unwind_to );

    my $block = $self->_current_block;
    foreach ( 1 .. $level ) {
        _exit_scope( $self, $block );
        $block = _outer_scope( $self, $block );
    }

    my $label_to;
    if( $tree->op == OP_GOTO ) {
        $label_to = $target->get_attribute( 'lbl_label' );
        # the check on successors is required during bytecode dump
        if( !$label_to || @{$label_to->successors} ) {
            $target->set_attribute( 'lbl_label', $label_to = _new_block( $self ) );
        }
    } else {
        my $label = $tree->op == OP_NEXT ? 'lbl_next' :
                    $tree->op == OP_LAST ? 'lbl_last' :
                                           'lbl_redo';
        $label_to = $target->get_attribute( $label )
            or die "Missing loop control label";
    }

    _add_jump $self, opcode_nm( OP_JUMP, to => $label_to ), $label_to;
    $self->_stack( _fake_stack( $stack_count ) );
    _add_blocks( $self, _new_fake_block( $self ) );
}

sub _emit_label {
    my( $self, $tree ) = @_;
    return unless $tree->has_attribute( 'label' );

    my $to = $tree->get_attribute( 'lbl_label' );
    # the check on successors is required during bytecode dump
    if( !$to || @{$to->successors} ) {
        $tree->set_attribute( 'lbl_label', $to = _new_block( $self ) );
    }

    _add_jump $self, opcode_nm( OP_JUMP, to => $to ), $to;
    _add_blocks $self, $tree->get_attribute( 'lbl_label' );
}

sub _discard_stack {
    my( $self ) = @_;
    my $need_discard = @{$self->_stack};

    while( @{$self->_stack} ) {
        my $op = pop @{$self->_stack};
        _add_bytecode $self, $op if    $op->opcode_n != OP_PHI
                                    && $op->opcode_n != OP_GET;
    }
    _add_bytecode $self, opcode_n( OP_DISCARD_STACK )
        if $self->is_stack && $need_discard;
}

sub _discard_value {
    my( $self ) = @_;
    my $top = $self->_stack->[-1];

    return if $top->opcode_n == OP_PHI;
    _pop( $self );
}

sub _discard_if_void {
    my( $self, $tree ) = @_;
    return if $tree->always_void;
    my $context = ( $tree->get_attribute( 'context' ) || 0 ) & CXT_CALL_MASK;
    return if $context != CXT_VOID;

    my $top = $self->_stack->[-1];
    return if    $top->opcode_n == OP_PHI
              || $top->opcode_n == OP_GET;
    _pop( $self );
}

sub _pattern {
    my( $self, $tree ) = @_;
    my $generator = Language::P::Intermediate::Generator->new
                        ( { _options  => $self->{_options},
                            _lexicals => $self->_lexicals,
                            is_stack  => $self->is_stack,
                            } );

    my $re = $generator->_generate_regex( $tree, $self->_code_segments->[0] );
    _add_value $self, opcode_nm( OP_CONSTANT_REGEX, value => $re->[0] );
    _add_value $self, opcode_nam( OP_MAKE_QR, _get_stack( $self, 1 ) )
        if $tree->op == OP_QL_QR;

    push @{$self->_code_segments}, @$re;
}

sub _interpolated_pattern {
    my( $self, $tree ) = @_;

    $self->dispatch( $tree->string );

    _add_value $self,
        opcode_npam( OP_EVAL_REGEX, $tree->pos,
                     _get_stack( $self, 1 ),
                     context => _context( $tree ),
                     flags   => $tree->flags,
                     );
    _add_value $self, opcode_nam( OP_MAKE_QR, _get_stack( $self, 1 ) )
        if $tree->op == OP_QL_QR;
}

sub _exit_scope {
    my( $self, $block ) = @_;

    _dump_out_stack( $self ) if @{$block->bytecode};

    foreach my $code ( reverse @{$block->bytecode} ) {
        _add_bytecode $self, @$code;
    }
}

my %regex_assertions =
  ( RX_ASSERTION_BEGINNING()        => OP_RX_BEGINNING,
    RX_ASSERTION_END()              => OP_RX_END,
    RX_ASSERTION_END_OR_NEWLINE()   => OP_RX_END_OR_NEWLINE,
    RX_ASSERTION_ANY_NONEWLINE()    => OP_RX_ANY_NONEWLINE,
    RX_ASSERTION_ANY()              => OP_RX_ANY,
    RX_ASSERTION_WORD_BOUNDARY()    => OP_RX_WORD_BOUNDARY,
    );

sub _regex_assertion {
    my( $self, $tree ) = @_;
    my $type = $tree->type;

    die "Unsupported assertion '$type'" unless $regex_assertions{$type};

    _add_bytecode $self, opcode_n( $regex_assertions{$type} );
}

sub _regex_assertion_group {
    my( $self, $tree ) = @_;
    my $type = $tree->type;

    my $next;
    if( $type == RX_GROUP_POSITIVE_LOOKAHEAD ) {
        _add_bytecode $self, opcode_nm( OP_RX_SAVE_POS,
                                        index => $self->_pos_count );
    } elsif( $type == RX_GROUP_NEGATIVE_LOOKAHEAD ) {
        $next = _new_block( $self );
        _add_bytecode $self, opcode_nm( OP_RX_BACKTRACK, to => $next );
    } else {
        die "Unsupported assertion '$type'" unless $regex_assertions{$type};
    }

    foreach my $c ( @{$tree->components} ) {
        $self->dispatch_regex( $c );
    }

    if( $type == RX_GROUP_POSITIVE_LOOKAHEAD ) {
        _add_bytecode $self, opcode_nm( OP_RX_RESTORE_POS,
                                        index => $self->_pos_count );
        $self->_pos_count( $self->_pos_count + 1 );
    } elsif( $type == RX_GROUP_NEGATIVE_LOOKAHEAD ) {
        _add_bytecode $self,
            opcode_n( OP_RX_POP_STATE ),
            opcode_n( OP_RX_FAIL );
        _add_blocks $self, $next;
    } else {
        die "Unsupported assertion '$type'" unless $regex_assertions{$type};
    }
}

sub _regex_quantifier {
    my( $self, $tree ) = @_;

    my( $start, $quant, $end ) = _new_blocks( $self, 3 );
    _add_bytecode $self, opcode_nm( OP_RX_START_GROUP, to => $quant );
    _add_blocks $self, $start;

    my $is_group = $tree->node->isa( 'Language::P::ParseTree::RXGroup' );
    my $capture = $is_group ? $tree->node->capture : 0;
    my $start_group = $self->_group_count;
    $self->_group_count( $start_group + 1 ) if $capture;

    if( $capture ) {
        foreach my $c ( @{$tree->node->components} ) {
            $self->dispatch_regex( $c );
        }
    } else {
        $self->dispatch_regex( $tree->node );
    }

    _add_bytecode $self, opcode_nm( OP_JUMP, to => $quant );
    _add_blocks $self, $quant;
    _add_bytecode $self,
        opcode_nm( OP_RX_QUANTIFIER,
                   min => $tree->min, max => $tree->max,
                   greedy => $tree->greedy,
                   group => ( $capture ? $start_group : -1 ),
                   subgroups_start => $start_group,
                   subgroups_end => $self->_group_count,
                   true => $start, false => $end );
    _add_blocks $self, $end;
}

sub _regex_group {
    my( $self, $tree ) = @_;

    my $start_group = $self->_group_count;
    if( $tree->capture ) {
        $self->_group_count( $start_group + 1 );

        _add_bytecode $self,
            opcode_nm( OP_RX_CAPTURE_START, group => $start_group );
    }

    foreach my $c ( @{$tree->components} ) {
        $self->dispatch_regex( $c );
    }

    if( $tree->capture ) {
        _add_bytecode $self,
            opcode_nm( OP_RX_CAPTURE_END, group => $start_group );
    }
}

sub _regex_exact {
    my( $self, $tree ) = @_;

    if( $tree->insensitive ) {
        _add_bytecode $self,
            opcode_nm( OP_RX_EXACT_I, characters => $tree->value,
                       length => length( $tree->value ) );
    } else {
        _add_bytecode $self,
            opcode_nm( OP_RX_EXACT, characters => $tree->value,
                       length => length( $tree->value ) );
    }
}

sub _regex_class {
    my( $self, $tree ) = @_;
    my( $elements, $ranges, $flags ) = ( '', '', 0 );

    $flags |= 1 if $tree->insensitive;
    foreach my $e ( @{$tree->elements} ) {
        if( $e->is_constant ) {
            $elements .= $e->value;
        } elsif( $e->isa( 'Language::P::ParseTree::RXRange' ) ) {
            $ranges .= $e->start . $e->end;
        } else {
            $flags |= $e->type;
        }
    }

    _add_bytecode $self,
        opcode_nm( OP_RX_CLASS,
                   elements => $elements,
                   ranges   => $ranges,
                   flags    => $flags,
                   );
}

sub _regex_special_class {
    my( $self, $tree ) = @_;

    _add_bytecode $self,
        opcode_nm( OP_RX_CLASS,
                   elements => '',
                   ranges   => '',
                   flags    => $tree->type,
                   );
}

sub _regex_alternate {
    my( $self, $tree, $end ) = @_;
    my $is_last = !$tree->right->[0]
                        ->isa( 'Language::P::ParseTree::RXAlternation' );
    my $next_l = _new_block( $self );
    $end ||= _new_block( $self );

    _add_bytecode $self, opcode_nm( OP_RX_TRY, to => $next_l );

    foreach my $c ( @{$tree->left} ) {
        $self->dispatch_regex( $c );
    }

    _add_bytecode $self, opcode_nm( OP_JUMP, to => $end );
    _add_blocks $self, $next_l;

    if( !$is_last ) {
        _regex_alternate( $self, $tree->right->[0], $end );
    } else {
        foreach my $c ( @{$tree->right} ) {
            $self->dispatch_regex( $c );
        }

        _add_bytecode $self, opcode_nm( OP_JUMP, to => $end );
        _add_blocks $self, $end;
    }
}

1;
