package Language::P::Intermediate::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_accessors( qw(_code_segments _current_basic_block _options
                              _label_count _temporary_count _current_block
                              _group_count file_name) );

use Scalar::Util qw();

use Language::P::Intermediate::Code;
use Language::P::Intermediate::BasicBlock;
use Language::P::Opcodes qw(:all);
use Language::P::ParseTree::PropagateContext;
use Language::P::ParseTree qw(:all);
use Language::P::Keywords qw(:all);
use Language::P::Assembly qw(:all);

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->_options( {} ) unless $self->_options;
    $self->_label_count( 0 );
    $self->_temporary_count( 0 );
    $self->_group_count( 0 );

    return $self;
}

sub set_option {
    my( $self, $option, $value ) = @_;

    if( $option eq 'dump-ir' ) {
        $self->_options->{$option} = 1;
    }

    return 0;
}

sub _add_bytecode {
    my( $self, @bytecode ) = @_;

    push @{$self->_current_basic_block->bytecode}, @bytecode;
}

sub _add_jump {
    my( $self, $op, @to ) = @_;

    $self->_current_basic_block->add_jump( $op, @to );
}

sub _add_blocks {
    my( $self, @blocks ) = @_;

    push @{$self->_code_segments->[0]->basic_blocks}, @blocks;
    _current_basic_block( $self, $blocks[-1] );
}

sub _new_blocks { map _new_block( $_[0] ), 1 .. $_[1] }
sub _new_block {
    my( $self ) = @_;

    return Language::P::Intermediate::BasicBlock
               ->new_from_label( 'L' . ++$self->{_label_count} );
}

sub push_block {
    my( $self, $is_sub ) = @_;

    $self->_current_block
      ( { outer    => $self->_current_block,
          is_sub   => $is_sub || 0,
          bytecode => [],
          } );

    return $self->_current_block;
}

sub pop_block {
    my( $self ) = @_;
    my $to_ret = $self->_current_block;

    $self->_current_block( $to_ret->{outer} );

    return $to_ret;
}

sub generate_regex {
    my( $self, $regex ) = @_;

    _generate_regex( $self, $regex, undef );
}

sub _generate_regex {
    my( $self, $regex, $outer ) = @_;

    $self->_code_segments( [] );
    $self->_group_count( 0 );

    push @{$self->_code_segments},
         Language::P::Intermediate::Code->new
             ( { type         => 3,
                 basic_blocks => [],
                 lexicals     => {},
                 } );
    if( $outer ) {
        push @{$outer->inner}, $self->_code_segments->[-1];
        Scalar::Util::weaken( $outer->inner->[-1] );
    }

    _add_blocks $self, _new_block( $self );
    _add_bytecode $self, opcode_n( OP_RX_START_MATCH );

    foreach my $e ( @{$regex->components} ) {
        $self->dispatch_regex( $e );
    }

    _add_bytecode $self,
        opcode_nm( OP_RX_ACCEPT, groups => $self->_group_count );

    die "Flags not supported" if $regex->flags;

    return $self->_code_segments;
}

sub generate_subroutine {
    my( $self, $tree, $outer ) = @_;

    my $context = Language::P::ParseTree::PropagateContext->new;
    $context->visit( $tree, CXT_VOID );

    _generate_bytecode( $self, 1, $tree->name, $outer, $tree->lines );
}

sub generate_bytecode {
    my( $self, $statements ) = @_;

    my $context = Language::P::ParseTree::PropagateContext->new;
    foreach my $tree ( @$statements ) {
        $context->visit( $tree, CXT_VOID );
    }

    _generate_bytecode( $self, 0, undef, undef, $statements );
}

sub _generate_bytecode {
    my( $self, $is_sub, $name, $outer, $statements ) = @_;

    $self->_code_segments( [] );

    push @{$self->_code_segments},
         Language::P::Intermediate::Code->new
             ( { type         => $is_sub ? 2 : 1,
                 name         => $name,
                 basic_blocks => [],
                 outer        => $outer,
                 lexicals     => {},
                 } );
    if( $outer ) {
        push @{$outer->inner}, $self->_code_segments->[-1];
        Scalar::Util::weaken( $outer->inner->[-1] );
    }

    _add_blocks $self, _new_block( $self );
    $self->push_block( $is_sub );

    foreach my $tree ( @$statements ) {
        $self->dispatch( $tree );
        _discard_if_void( $self, $tree );
    }

    $self->pop_block;

    _add_bytecode $self, opcode_n( OP_END );

    # eliminate edges from a node with multiple successors to a node
    # with multiple predecessors by inserting an empty node and
    # splitting the edge
    foreach my $block ( @{$self->_code_segments->[0]->basic_blocks} ) {
        next if @{$block->successors} != 2;
        my @to_change;
        foreach my $succ ( @{$block->successors} ) {
            push @to_change, $succ if @{$succ->predecessors} >= 2;
        }
        # in two steps to avoid changing successors while iterating
        foreach my $succ ( @to_change ) {
            _add_blocks $self, _new_block( $self );
            _add_jump $self, opcode_nm( OP_JUMP, to => $succ ), $succ;
            $block->_change_successor( $succ, $self->_current_basic_block );
        }
    }

    if( $self->_options->{'dump-ir'} ) {
        ( my $outfile = $self->file_name ) =~ s/(\.\w+)?$/.ir/;
        open my $ir_dump, '>', $outfile || die "Can't open '$outfile': $!";

        foreach my $cs ( @{$self->_code_segments} ) {
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
    'Language::P::ParseTree::QuotedString'           => '_quoted_string',
    'Language::P::ParseTree::Subscript'              => '_subscript',
    'Language::P::ParseTree::Jump'                   => '_jump',
    'Language::P::ParseTree::Pattern'                => '_pattern',
    'Language::P::ParseTree::Parentheses'            => '_parentheses',
    );

my %dispatch_cond =
  ( 'Language::P::ParseTree::BinOp'          => '_binary_op_cond',
    'DEFAULT'                                => '_anything_cond',
    );

my %dispatch_regex =
  ( 'Language::P::ParseTree::RXQuantifier'   => '_regex_quantifier',
    'Language::P::ParseTree::RXGroup'        => '_regex_group',
    'Language::P::ParseTree::Constant'       => '_regex_exact',
    'Language::P::ParseTree::RXAlternation'  => '_regex_alternate',
    'Language::P::ParseTree::RXAssertion'    => '_regex_assertion',
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

sub _indirect {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    if( $tree->indirect ) {
        $self->dispatch( $tree->indirect );
    } else {
        _add_bytecode $self,
             opcode_nm( OP_GLOBAL, name => 'STDOUT', slot => VALUE_HANDLE );
    }

    foreach my $arg ( @{$tree->arguments} ) {
        $self->dispatch( $arg );
    }

    _add_bytecode $self,
         opcode_nm( OP_MAKE_LIST, count => @{$tree->arguments} + 1 ),
         opcode_n( $tree->function );
}

sub _builtin {
    my( $self, $tree ) = @_;

    if( $tree->function == OP_UNDEF && !$tree->arguments ) {
        _emit_label( $self, $tree );
        _add_bytecode $self, opcode_n( OP_CONSTANT_UNDEF );
    } elsif(   $OP_ATTRIBUTES{$tree->function}->{flags}
             & Language::P::Opcodes::FLAG_UNARY ) {
        _emit_label( $self, $tree );
        foreach my $arg ( @{$tree->arguments || []} ) {
            $self->dispatch( $arg );
        }

        _add_bytecode $self, opcode_n( $tree->function );
    } else {
        return _function_call( $self, $tree );
    }
}

sub _function_call {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    foreach my $arg ( @{$tree->arguments || []} ) {
        $self->dispatch( $arg );
    }

    _add_bytecode $self,
         opcode_nm( OP_MAKE_LIST, count => scalar @{$tree->arguments || []} );

    if( ref( $tree->function ) ) {
        $self->dispatch( $tree->function );
        _add_bytecode $self,
             opcode_nm( OP_CALL, context => $tree->get_attribute( 'context' ) & CXT_CALL_MASK );
    } else {
        if( $tree->function == OP_RETURN ) {
            my $block = $self->_current_block;
            while( $block ) {
                _exit_scope( $self, $block );
                last if $block->{is_sub};
                $block = $block->{outer};
            }
        }

        _add_bytecode $self, opcode_n( $tree->function );
    }
}

sub _list {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    foreach my $arg ( @{$tree->expressions} ) {
        $self->dispatch( $arg );
    }

    _add_bytecode $self,
         opcode_nm( OP_MAKE_LIST, count => @{$tree->expressions} + 0 );
}

sub _unary_op {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    $self->dispatch( $tree->left );

    _add_bytecode $self, opcode_n( $tree->op );
}

sub _local {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    die "Can only localize global for now"
        unless $tree->left->isa( 'Language::P::ParseTree::Symbol' );

    my $index = $self->{_temporary_count}++;
    _add_bytecode $self,
         opcode_nm( OP_LOCALIZE_GLOB_SLOT,
                   name  => $tree->left->name,
                   slot  => $tree->left->sigil,
                   index => $index,
                   );

    push @{$self->_current_block->{bytecode}},
         [ opcode_nm( OP_RESTORE_GLOB_SLOT,
                     name  => $tree->left->name,
                     slot  => $tree->left->sigil,
                     index => $index,
                     ),
           ];
}

sub _parentheses {
    my( $self, $tree ) = @_;

    $self->dispatch( $tree->left );
}

sub _binary_op {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    if( $tree->op == OP_LOG_AND || $tree->op == OP_LOG_OR ) {
        $self->dispatch( $tree->left );

        my( $right, $end ) = _new_blocks( $self, 2 );

        # jump to $end if evalutating right is not necessary
        _add_bytecode $self,
             opcode_n( OP_DUP );
        _add_jump $self,
             opcode_nm( OP_JUMP_IF_TRUE,
                        $tree->op == OP_LOG_AND ?
                            ( true => $right, false => $end ) :
                            ( true => $end,   false => $right ) ),
             $right, $end;

        _add_blocks $self, $right;

        # evalutates right only if this is the correct return value
        _add_bytecode $self, opcode_n( OP_POP );
        $self->dispatch( $tree->right );
        _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;
        _add_blocks $self, $end;
    } elsif( $tree->op == OP_ASSIGN ) {
        $self->dispatch( $tree->right );
        $self->dispatch( $tree->left );

        _add_bytecode $self,
                      opcode_n( OP_SWAP ),
                      opcode_n( $tree->op );
    } else {
        $self->dispatch( $tree->left );
        $self->dispatch( $tree->right );

        _add_bytecode $self, opcode_n( $tree->op );
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

    _add_jump $self, opcode_nm( $conditionals{$tree->op},
                                true => $true, false => $false ), $true, $false;
}

sub _anything_cond {
    my( $self, $tree, $true, $false ) = @_;

    $self->dispatch( $tree );

    _add_jump $self, opcode_nm( OP_JUMP_IF_TRUE, true => $true, false => $false ), $true, $false;
}

sub _constant {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );
    my $v;

    if( $tree->is_number ) {
        if( $tree->flags & NUM_INTEGER ) {
            _add_bytecode $self,
                 opcode_n( OP_CONSTANT_INTEGER, $tree->value );
        } elsif( $tree->flags & NUM_FLOAT ) {
            _add_bytecode $self,
                 opcode_n( OP_CONSTANT_FLOAT, $tree->value );
        } elsif( $tree->flags & NUM_OCTAL ) {
            _add_bytecode $self,
                 opcode_n( OP_CONSTANT_INTEGER, oct '0' . $tree->value );
        } elsif( $tree->flags & NUM_HEXADECIMAL ) {
            _add_bytecode $self,
                 opcode_n( OP_CONSTANT_INTEGER, oct '0x' . $tree->value );
        } elsif( $tree->flags & NUM_BINARY ) {
            _add_bytecode $self,
                 opcode_n( OP_CONSTANT_INTEGER, oct '0b' . $tree->value );
        } else {
            die "Unhandled flags value";
        }
    } elsif( $tree->is_string ) {
        _add_bytecode $self,
             opcode_n( OP_CONSTANT_STRING, $tree->value );
    } else {
        die "Neither number nor string";
    }
}

sub _symbol {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    _add_bytecode $self,
         opcode_nm( OP_GLOBAL, name => $tree->name, slot => $tree->sigil );
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

sub _do_lexical_access {
    my( $self, $tree, $level, $is_decl ) = @_;

    # maybe to it while parsing, in _find_symbol/_process_lexical_declaration
    my $lex_info = $self->_code_segments->[0]->lexicals->{$tree}
                       ||= { level => $level, lexical => $tree };

    _add_bytecode $self,
         opcode_nm( OP_LEXICAL,
                    lexical  => $tree,
                    level    => $level,
                    );

    if( $is_decl ) {
        $lex_info->{declaration} = 1;

        push @{$self->_current_block->{bytecode}},
             [ opcode_nm( OP_LEXICAL_CLEAR,
                          lexical => $tree,
                          level   => $level,
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

    $self->push_block;

    _add_blocks $self, $start_cond;
    $self->dispatch_cond( $tree->condition,
                          $is_until ? ( $end_loop, $start_loop ) :
                                      ( $start_loop, $end_loop ) );

    _add_blocks $self, $start_loop;
    $self->dispatch( $tree->block );
    _discard_if_void( $self, $tree->block )
        unless $tree->block->isa( 'Language::P::ParseTree::Block' );

    if( $tree->continue ) {
        _add_jump $self, opcode_nm( OP_JUMP, to => $start_continue ), $start_continue;

        _add_blocks $self, $start_continue;
        $self->dispatch( $tree->continue );
    }

    _add_jump $self, opcode_nm( OP_JUMP, to => $start_cond ), $start_cond;

    _add_blocks $self, $end_loop;
    _exit_scope( $self, $self->_current_block );
    $self->pop_block;
}

sub _foreach {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $is_lexical = $tree->variable->isa( 'Language::P::ParseTree::LexicalDeclaration' );

    my( $start_step, $start_loop, $start_continue, $exit_loop, $end_loop ) =
        _new_blocks( $self, 5 );
    $tree->set_attribute( 'lbl_next', $tree->continue ? $start_continue :
                                                        $start_step );
    $tree->set_attribute( 'lbl_last', $end_loop );
    $tree->set_attribute( 'lbl_redo', $start_loop );

    $self->push_block;

    $self->dispatch( $tree->expression );
    _add_bytecode $self, opcode_nm( OP_MAKE_LIST, count => 1 );

    my $iterator = $self->{_temporary_count}++;
    my( $glob, $slot );
    _add_bytecode $self,
        opcode_nm( OP_ITERATOR ),
        opcode_nm( OP_TEMPORARY_SET, index => $iterator );

    if( !$is_lexical ) {
        $glob = $self->{_temporary_count}++;
        $slot = $self->{_temporary_count}++;

        _add_bytecode $self,
            opcode_nm( OP_GLOBAL, name => $tree->variable->name, slot => VALUE_GLOB ),
            opcode_n( OP_DUP ),
            opcode_nm( OP_GLOB_SLOT,   slot  => VALUE_SCALAR ),
            opcode_nm( OP_TEMPORARY_SET, index => $slot ),
            opcode_nm( OP_TEMPORARY_SET, index => $glob );

        push @{$self->_current_block->{bytecode}},
             [ opcode_nm( OP_TEMPORARY,     index => $glob ),
               opcode_nm( OP_TEMPORARY,     index => $slot ),
               opcode_nm( OP_GLOB_SLOT_SET, slot  => VALUE_SCALAR ),
               ];
    }

    _add_jump $self, opcode_nm( OP_JUMP, to => $start_step ), $start_step;
    _add_blocks $self, $start_step;

    if( !$is_lexical ) {
        _add_bytecode $self,
            opcode_nm( OP_TEMPORARY,     index => $iterator ),
            opcode_nm( OP_ITERATOR_NEXT ),
            opcode_n( OP_DUP );
        _add_jump $self,
            opcode_nm( OP_JUMP_IF_NULL, true => $exit_loop, false => $start_loop ), $exit_loop, $start_loop;

        _add_blocks $self, $start_loop;
        _add_bytecode $self,
            opcode_nm( OP_TEMPORARY,     index => $glob ),
            opcode_n( OP_SWAP ),
            opcode_nm( OP_GLOB_SLOT_SET, slot  => VALUE_SCALAR );
    } else {
        _add_bytecode $self,
            opcode_nm( OP_TEMPORARY,      index => $iterator ),
            opcode_n( OP_ITERATOR_NEXT ),
            opcode_n( OP_DUP );
        _add_jump $self,
            opcode_nm( OP_JUMP_IF_NULL, true => $exit_loop, false => $start_loop ), $exit_loop, $start_loop;

        _add_blocks $self, $start_loop;
        _add_bytecode $self,
            opcode_nm( OP_LEXICAL_SET,  lexical => $tree->variable );

        $self->_code_segments->[0]->lexicals->{$tree->variable}
            = { level       => 0,
                lexical     => $tree->variable,
                };
    }

    $self->dispatch( $tree->block );
    _discard_if_void( $self, $tree->block )
        unless $tree->block->isa( 'Language::P::ParseTree::Block' );

    if( $tree->continue ) {
        _add_jump $self, opcode_nm( OP_JUMP, to => $start_continue ), $start_continue;

        _add_blocks $self, $start_continue;
        $self->dispatch( $tree->continue );
    }

    _add_jump $self, opcode_nm( OP_JUMP, to => $start_step ), $start_step;

    _add_blocks $self, $exit_loop;
    _add_bytecode $self, opcode_n( OP_POP );
    _add_jump $self, opcode_nm( OP_JUMP, to => $end_loop ), $end_loop;
    _add_blocks $self, $end_loop;

    _exit_scope( $self, $self->_current_block );
    $self->pop_block;
}

sub _for {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my( $start_cond, $start_loop, $start_step, $end_loop ) = _new_blocks( $self, 4 );
    $tree->set_attribute( 'lbl_next', $start_step );
    $tree->set_attribute( 'lbl_last', $end_loop );
    $tree->set_attribute( 'lbl_redo', $start_loop );

    $self->push_block;

    $self->dispatch( $tree->initializer );
    _discard_if_void( $self, $tree->initializer );

    _add_jump $self,
         opcode_nm( OP_JUMP, to => $start_cond ), $start_cond;
    _add_blocks $self, $start_cond;

    $self->dispatch_cond( $tree->condition, $start_loop, $end_loop );

    _add_blocks $self, $start_loop;
    $self->dispatch( $tree->block );
    _discard_if_void( $self, $tree->block )
        unless $tree->block->isa( 'Language::P::ParseTree::Block' );

    _add_jump $self,
         opcode_nm( OP_JUMP, to => $start_step ), $start_step;

    _add_blocks $self, $start_step;
    $self->dispatch( $tree->step );
    _discard_if_void( $self, $tree->step );
    _add_jump $self, opcode_nm( OP_JUMP, to => $start_cond ), $start_cond;

    _add_blocks $self, $end_loop;
    _exit_scope( $self, $self->_current_block );
    $self->pop_block;
}

sub _cond {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    $self->push_block;

    my @blocks;
    my $current = $self->_current_basic_block;
    push @blocks, _new_block( $self );
    if( $tree->iffalse ) {
        push @blocks, _new_block( $self );
        _current_basic_block( $self, $blocks[-1] );
        $self->dispatch( $tree->iffalse->block );
        _add_jump $self, opcode_nm( OP_JUMP, to => $blocks[0] ), $blocks[0];
    }
    foreach my $elsif ( reverse @{$tree->iftrues} ) {
        my $next = $blocks[-1];
        my $is_unless = $elsif->block_type eq 'unless';
        my( $cond_block, $then_block ) = _new_blocks( $self, 2 );
        _current_basic_block( $self, $cond_block );
        $self->dispatch_cond( $elsif->condition,
                              $is_unless ? ( $next, $then_block ) :
                                           ( $then_block, $next ) );
        push @blocks, $then_block, $cond_block;
        _current_basic_block( $self, $then_block );
        $self->dispatch( $elsif->block );
        _discard_if_void( $self, $elsif->block )
            unless $elsif->block->isa( 'Language::P::ParseTree::Block' );

        _add_jump $self, opcode_nm( OP_JUMP, to => $blocks[0] ), $blocks[0];
    }

    $current->add_jump( opcode_nm( OP_JUMP, to => $blocks[-1] ), $blocks[-1] );
    _add_blocks $self, reverse @blocks;

    _exit_scope( $self, $self->_current_block );
    $self->pop_block;
}

sub _ternary {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my( $end, $true, $false ) = _new_blocks( $self, 3 );
    $self->dispatch_cond( $tree->condition, $true, $false );

    _add_blocks $self, $true;
    $self->dispatch( $tree->iftrue );
    _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;

    _add_blocks $self, $false;
    $self->dispatch( $tree->iffalse );
    _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;

    _add_blocks $self, $end;
}

sub _block {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    $self->push_block;

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
        _discard_if_void( $self, $line );
    }

    _exit_scope( $self, $self->_current_block );
    $self->pop_block;
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

    $self->push_block;

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
        _discard_if_void( $self, $line );
    }

    _exit_scope( $self, $self->_current_block );
    $self->pop_block;

    if( $tree->continue ) {
        _add_jump $self, opcode_nm( OP_JUMP, to => $start_continue ), $start_continue;

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

    _add_bytecode $self,
        opcode_n( OP_CONSTANT_SUB, $sub ),
        opcode_n( OP_MAKE_CLOSURE );
}

sub _subroutine {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $generator = Language::P::Intermediate::Generator->new
                        ( { _options => { %{$self->{_options}},
                                          # performed by caller
                                          'dump-ir' => 0,
                                          },
                            } );
    my $code_segments =
      _generate_bytecode( $generator, 1, $tree->name,
                          $self->_code_segments->[0], $tree->lines );
    push @{$self->_code_segments}, @$code_segments;

    return $code_segments->[0];
}

sub _quoted_string {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    if( @{$tree->components} == 1 ) {
        $self->dispatch( $tree->components->[0] );

        _add_bytecode $self, opcode_n( OP_STRINGIFY );

        return;
    }

    _add_bytecode $self, opcode_n( OP_FRESH_STRING, '' );
    for( my $i = 0; $i < @{$tree->components}; ++$i ) {
        $self->dispatch( $tree->components->[$i] );

        _add_bytecode $self, opcode_n( OP_CONCAT_ASSIGN );
    }
}

sub _subscript {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    die if $tree->reference;

    $self->dispatch( $tree->subscript );
    $self->dispatch( $tree->subscripted );

    if( $tree->type == VALUE_ARRAY ) {
        _add_bytecode $self, opcode_n( OP_ARRAY_ELEMENT );
    } elsif( $tree->type == VALUE_HASH ) {
        _add_bytecode $self, opcode_n( OP_HASH_ELEMENT );
    } else {
        die $tree->type;
    }
}

# find the node that is the target of a goto or the loop node that
# last/redo/next controls
sub _find_jump_target {
    my( $self, $node ) = @_;
    return $node->get_attribute( 'target' ) if $node->has_attribute( 'target' );
    return if ref $node->left; # dynamic jump
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

    die "Jump without static target" unless $target; # requires stack unwinding

    my $unwind_to = $tree->op == OP_GOTO ?
                        _find_ancestor( $self, $tree, $target ) :
                        $target;
    my $level = _unwind_level( $self, $tree, $unwind_to );

    my $block = $self->_current_block;
    foreach ( 1 .. $level ) {
        _exit_scope( $self, $block );
        $block = $block->{outer};
    }

    my $label_to;
    if( $tree->op == OP_GOTO ) {
        $label_to = $target->get_attribute( 'lbl_label' );
        if( !$label_to ) {
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
    _add_blocks( $self, _new_block( $self ) );
}

sub _emit_label {
    my( $self, $tree ) = @_;
    return unless $tree->has_attribute( 'label' );

    if( !$tree->has_attribute( 'lbl_label' ) ) {
        $tree->set_attribute( 'lbl_label', _new_block( $self ) );
    }

    my $to = $tree->get_attribute( 'lbl_label' );
    _add_jump $self, opcode_nm( OP_JUMP, to => $to ), $to;
    _add_blocks $self, $tree->get_attribute( 'lbl_label' );
}

sub _discard_if_void {
    my( $self, $tree ) = @_;
    my $context = ( $tree->get_attribute( 'context' ) || 0 ) & CXT_CALL_MASK;
    return if $context != CXT_VOID;

    _add_bytecode $self, opcode_n( OP_POP );
}

sub _pattern {
    my( $self, $tree ) = @_;
    my $generator = Language::P::Intermediate::Generator->new
                        ( { _options => $self->{_options},
                            } );

    my $re = $generator->_generate_regex( $tree, $self->_code_segments->[0] );
    _add_bytecode $self, opcode_n( OP_CONSTANT_REGEX, $re->[0] );
}

sub _exit_scope {
    my( $self, $block ) = @_;

    foreach my $code ( reverse @{$block->{bytecode}} ) {
        _add_bytecode $self, @$code;
    }
}

my %regex_assertions =
  ( START_SPECIAL => OP_RX_START_SPECIAL,
    END_SPECIAL   => OP_RX_END_SPECIAL,
    );

sub _regex_assertion {
    my( $self, $tree ) = @_;
    my $type = $tree->type;

    die "Unsupported assertion '$type'" unless $regex_assertions{$type};

    _add_bytecode $self, opcode_n( $regex_assertions{$type} );
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
                   group => ( $capture ? $start_group : undef ),
                   subgroups_start => $start_group,
                   subgroups_end => $self->_group_count,
                   true => $start, false => $end );
    _add_blocks $self, $end;
}

sub _regex_group {
    my( $self, $tree ) = @_;

    if( $tree->capture ) {
        _add_bytecode $self,
            opcode_nm( OP_RX_CAPTURE_START, group => $self->_group_count );
    }

    foreach my $c ( @{$tree->components} ) {
        $self->dispatch_regex( $c );
    }

    if( $tree->capture ) {
        _add_bytecode $self,
            opcode_nm( OP_RX_CAPTURE_END, group => $self->_group_count );
        $self->_group_count( $self->_group_count + 1 );
    }
}

sub _regex_exact {
    my( $self, $tree ) = @_;

    _add_bytecode $self,
        opcode_nm( OP_RX_EXACT, string => $tree->value,
                   length => length( $tree->value ) );
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
