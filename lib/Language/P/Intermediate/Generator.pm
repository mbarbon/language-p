package Language::P::Intermediate::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_accessors( qw(_code_segments _current_basic_block _options
                              _label_count _temporary_count _current_block
                              _group_count _main file_name) );

use Scalar::Util qw();

use Language::P::Intermediate::Code qw(:all);
use Language::P::Intermediate::BasicBlock;
use Language::P::Opcodes qw(:all);
use Language::P::ParseTree::PropagateContext;
use Language::P::Constants qw(:all);
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
    my $block = $self->_current_block;

    return Language::P::Intermediate::BasicBlock->new_from_label
               ( 'L' . ++$self->{_label_count},
                 $block ? $block->{lexical_state} : 0,
                 $block ? $block->{id} : 0 );
}

sub _start_bb {
    my( $self ) = @_;
    return if @{$self->_current_basic_block->bytecode} == 1;
    my $block = _new_block( $self );

    _add_jump $self,
         opcode_nm( OP_JUMP, to => $block ), $block;
    _add_blocks $self, $block;

    return $block;
}

sub _context { $_[0]->get_attribute( 'context' ) & CXT_CALL_MASK }

sub push_block {
    my( $self, $flags, $start_pos, $exit_pos, $context ) = @_;
    my $id = @{$self->_code_segments->[0]->scopes};
    my $outer = $self->_current_block;
    my $bytecode = [];

    Carp::confess( "Instructions at scope start" )
      if @{$self->_current_basic_block->bytecode} != 1;
    # TODO encapsulation
    $self->_current_basic_block->{scope} = $id;

    push @{$self->_code_segments->[0]->scopes},
         { outer         => $outer ? $outer->{id} : -1,
           bytecode      => $bytecode,
           id            => $id,
           flags         => $flags,
           context       => $context || 0, # for eval BLOCK only
           pos_s         => $start_pos,
           pos_e         => $exit_pos,
           lexical_state => $outer ? $outer->{lexical_state} : 0,
           };

    $self->_current_block
      ( { outer         => $outer,
          flags         => $flags,
          bytecode      => $bytecode,
          pos           => $exit_pos,
          id            => $id,
          lexical_state => $outer ? $outer->{lexical_state} : 0,
          } );

    return $self->_current_block;
}

sub pop_block {
    my( $self ) = @_;
    my $to_ret = $self->_current_block;

    $self->_current_block( $to_ret->{outer} );

    return $to_ret;
}

sub create_main {
    my( $self, $outer, $is_eval ) = @_;
    my $main = Language::P::Intermediate::Code->new
                   ( { type         => $is_eval ? CODE_EVAL : CODE_MAIN,
                       name         => undef,
                       basic_blocks => [],
                       outer        => $outer,
                       lexicals     => { max_stack => 0 },
                       prototype    => undef,
                       } );
    $self->_main( $main );
}

sub create_eval_context {
    my( $self, $indices, $lexicals ) = @_;
    my $lex = {};
    my $cxt = Language::P::Intermediate::Code->new
                  ( { type     => CODE_MAIN,
                      name     => undef,
                      outer    => undef,
                      lexicals => { map => $lex },
                      } );
    while( my( $name, $index ) = each %$indices ) {
        my $lexical = $lexicals->names->{$name};
        $lex->{$lexical} =
          { index       => $index,
            outer_index => -1,
            name        => $lexical->name,
            sigil       => $lexical->sigil,
            symbol_name => $lexical->symbol_name,
            level       => 0,
            in_pad      => 1,
            };
    }

    return $cxt;
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
             ( { type         => CODE_REGEX,
                 basic_blocks => [],
                 } );
    push @{$outer->inner}, $self->_code_segments->[-1] if $outer;

    _add_blocks $self, _new_block( $self );
    _add_bytecode $self, opcode_n( OP_RX_START_MATCH );

    foreach my $e ( @{$regex->components} ) {
        $self->dispatch_regex( $e );
    }

    _add_bytecode $self,
        opcode_nm( OP_RX_ACCEPT, groups => $self->_group_count );

    die "Flags i, o, g, c not supported"
      if $regex->flags & ( FLAG_RX_CASE_INSENSITIVE|FLAG_RX_ONCE );

    return $self->_code_segments;
}

sub generate_use {
    my( $self, $tree ) = @_;

    my $context = Language::P::ParseTree::PropagateContext->new;
    $context->visit( $tree, CXT_VOID );

    $self->_code_segments( [] );

    my $head = $self->_new_block;
    my $empty = $self->_new_block;
    my $body = $self->_new_block;
    my $return = $self->_new_block;

    push @{$self->_code_segments},
         Language::P::Intermediate::Code->new
             ( { type         => CODE_SUB,
                 name         => 'BEGIN',
                 basic_blocks => [],
                 outer        => undef,
                 lexicals     => { max_stack => 1 },
                 prototype    => undef,
                 } );

    _add_blocks $self, $head;
    $self->push_block( SCOPE_SUB|SCOPE_MAIN, $tree->pos_s, $tree->pos_e );

    _lexical_state( $self, $tree->lexical_state );

    # check the Perl version
    if( $tree->version && !$tree->package ) {
        # compare version
        _add_bytecode $self,
                      opcode_nm( OP_CONSTANT_INTEGER, value => $tree->version ),
                      opcode_npm( OP_GLOBAL, $tree->pos,
                                  name => ']',
                                  slot => VALUE_SCALAR );
        _add_jump $self,
                  opcode_nm( OP_JUMP_IF_F_LT,
                             true  => $return,
                             false => $body ),
            $return, $body;

        # TODO use version objects
        # Perl v6.0.0 required--this is only v5.10.1, stopped
        _add_blocks $self, $body;
        _add_bytecode $self,
                      opcode_nm( OP_FRESH_STRING, value => 'Perl ' ),
                      opcode_nm( OP_CONSTANT_FLOAT, value => $tree->version ),
                      opcode_nm( OP_CONSTANT_STRING, value => ' required--this is only ' ),
                      opcode_nm( OP_GLOBAL, name => ']', slot => VALUE_SCALAR ),
                      opcode_nm( OP_CONSTANT_STRING, value => ', stopped' ),
                      opcode_nm( OP_CONCATENATE ),
                      opcode_nm( OP_CONCATENATE ),
                      opcode_nm( OP_CONCATENATE ),
                      opcode_nm( OP_CONCATENATE ),
                      opcode_nm( OP_MAKE_LIST, count => 1 ),
                      opcode_np( OP_DIE, $tree->pos );
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
    _add_bytecode $self,
         opcode_nm( OP_CONSTANT_STRING, value => "$file.pm" ),
         opcode_npm( OP_REQUIRE_FILE, $tree->pos, context => CXT_VOID ),
         opcode_n( OP_POP );

    # TODO check version

    # always evaluate arguments, even if no import/unimport is present
    _add_bytecode $self,
        opcode_nm( OP_CONSTANT_STRING, value => $tree->package );
    if( $tree->import ) {
        foreach my $arg ( @{$tree->import} ) {
            $self->dispatch( $arg );
        }
        _add_bytecode $self,
            opcode_nm( OP_MAKE_LIST, count => @{$tree->import} + 1 );
    } else {
        _add_bytecode $self,
            opcode_nm( OP_MAKE_LIST, count => 1 );
    }

    _add_bytecode $self,
        opcode_nm( OP_CONSTANT_STRING, value => $tree->package ),
        opcode_npm( OP_FIND_METHOD, $tree->pos,
                    method => $tree->is_no ? 'unimport' : 'import' ),
        opcode_n( OP_DUP );
    _add_jump $self,
        opcode_nm( OP_JUMP_IF_NULL,
                   true  => $empty,
                   false => $body ),
        $empty, $body;

    # empty block, for SSA conversion
    _add_blocks $self, $empty;
    _add_bytecode $self, # pop undef value and arguments
        opcode_n( OP_POP ),
        opcode_n( OP_POP );
    _add_jump $self,
        opcode_nm( OP_JUMP, to => $return ),
        $return;

    # call the import method
    _add_blocks $self, $body;

    _add_bytecode $self,
        opcode_npm( OP_CALL, $tree->pos, context => CXT_VOID ),
        opcode_n( OP_POP );
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

    if( !$is_sub && $self->_main ) {
        push @{$self->_code_segments}, $self->_main;
        $self->_main( undef );
    } else {
        push @{$self->_code_segments},
             Language::P::Intermediate::Code->new
                 ( { type         => $is_sub ? CODE_SUB : CODE_MAIN,
                     name         => $name,
                     basic_blocks => [],
                     outer        => $outer,
                     lexicals     => { max_stack => $is_sub ? 1 : 0 },
                     prototype    => $prototype,
                     } );
    }
    push @{$outer->inner}, $self->_code_segments->[-1] if $outer;

    _add_blocks $self, _new_block( $self );
    my $is_eval = $self->_code_segments->[-1]->is_eval;
    my $block_flags =   ( $is_sub  ? SCOPE_SUB : 0 )
                      | ( $is_eval ? SCOPE_EVAL : 0 )
                      |              SCOPE_MAIN;

    $self->push_block( 0, undef, undef );
    $self->push_block( $block_flags, $pos_s, $pos_e );

    foreach my $tree ( @$statements ) {
        $self->dispatch( $tree );
        _discard_if_void( $self, $tree );
    }

    $self->pop_block;

    if( @{$self->_current_basic_block->bytecode} > 1 ) {
        my $end = _new_block( $self );
        _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;
        _add_blocks $self, $end;
    }
    _add_bytecode $self, opcode_n( OP_END );

    $self->pop_block;

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
  ( 'Language::P::ParseTree::RXQuantifier'   => '_regex_quantifier',
    'Language::P::ParseTree::RXGroup'        => '_regex_group',
    'Language::P::ParseTree::Constant'       => '_regex_exact',
    'Language::P::ParseTree::RXAlternation'  => '_regex_alternate',
    'Language::P::ParseTree::RXAssertion'    => '_regex_assertion',
    'Language::P::ParseTree::RXClass'        => '_regex_class',
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
    my $scope_id = $self->_current_block->{id};
    my $state_id = @{$self->_code_segments->[0]->lexical_states};

    push @{$self->_code_segments->[0]->lexical_states},
         { scope    => $scope_id,
           package  => $tree->package,
           hints    => $tree->hints,
           warnings => $tree->warnings,
           };
    $self->_code_segments->[0]->scopes->[$scope_id]->{flags} |= SCOPE_LEX_STATE;
    $self->_current_block->{lexical_state} = $state_id;

    # avoid generating a new basic block if the current basic block only
    # contains a label
    my $bb = $self->_current_basic_block;
    if( @{$bb->bytecode} == 1 ) {
        # TODO emit _save at block start
        _add_bytecode $self,
            opcode_nm( OP_LEXICAL_STATE_SET,  index => $state_id );

        $bb->{lexical_state} = $state_id;
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

    if( $tree->indirect ) {
        $self->dispatch( $tree->indirect );
    } else {
        _add_bytecode $self,
             opcode_npm( OP_GLOBAL, $tree->pos,
                         name => 'STDOUT',
                         slot => VALUE_HANDLE );
    }

    foreach my $arg ( @{$tree->arguments} ) {
        $self->dispatch( $arg );
    }

    _add_bytecode $self,
         opcode_nm( OP_MAKE_LIST, count => scalar @{$tree->arguments} ),
         opcode_npm( $tree->function, $tree->pos,
                     context   => _context( $tree ) );
}

sub _builtin {
    my( $self, $tree ) = @_;
    my $op_flags = $OP_ATTRIBUTES{$tree->function}->{flags};

    if( $tree->function == OP_UNDEF && !$tree->arguments ) {
        _emit_label( $self, $tree );
        _add_bytecode $self, opcode_n( OP_CONSTANT_UNDEF );
    } elsif(    $tree->function == OP_EXISTS
             && $tree->arguments->[0]->isa( 'Language::P::ParseTree::Subscript' ) ) {
        _emit_label( $self, $tree );

        my $arg = $tree->arguments->[0];

        $self->dispatch( $arg->subscript );
        $self->dispatch( $arg->subscripted );

        _add_bytecode $self,
            opcode_npm( $arg->type == VALUE_ARRAY ? OP_VIVIFY_ARRAY :
                                                    OP_VIVIFY_HASH,
                        $tree->pos, context => CXT_SCALAR )
              if $arg->reference;
        _add_bytecode $self,
            opcode_npm( $arg->type == VALUE_ARRAY ? OP_EXISTS_ARRAY :
                                                    OP_EXISTS_HASH,
                        $tree->pos, context => _context( $tree ) );
    } elsif( $op_flags & Language::P::Opcodes::FLAG_UNARY ) {
        _emit_label( $self, $tree );
        foreach my $arg ( @{$tree->arguments || []} ) {
            $self->dispatch( $arg );
        }

        if( $tree->function == OP_EVAL ) {
            my $plex = $tree->get_attribute( 'lexicals' );
            my %lex;
            while( my( $n, $l ) = each %$plex ) {
                $lex{$n} = _allocate_lexical( $self, $self->_code_segments->[0],
                                              $l, 1 )->{index};
            }
            my $env = $tree->get_attribute( 'environment' );
            _add_bytecode $self,
                opcode_npm( $tree->function, $tree->pos,
                            context  => _context( $tree ),
                            hints    => $env->{hints},
                            warnings => $env->{warnings},
                            package  => $env->{package},
                            lexicals => \%lex,
                            globals  => $tree->get_attribute( 'globals' ) );
        } elsif( $op_flags & Language::P::Opcodes::FLAG_VARIADIC ) {
            _add_bytecode $self,
                opcode_npm( $tree->function, $tree->pos,
                            arg_count => scalar @{$tree->arguments || []},
                            context   => _context( $tree ) );
        } else {
            _add_bytecode $self,
                opcode_npm( $tree->function, $tree->pos,
                            context => _context( $tree ) );
        }
    } else {
        return _function_call( $self, $tree );
    }
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
                _add_bytecode $self, opcode_np( OP_REFERENCE, $arg->pos );
            } else {
                --$argcount;
            }
        }
        ++$argcount;
        ++$i;
    }

    _add_bytecode $self,
         opcode_nm( OP_MAKE_LIST, count => $argcount );

    if( $is_func ) {
        $self->dispatch( $tree->function );
        _add_bytecode $self,
             opcode_npm( OP_CALL, $tree->pos, context => _context( $tree ) );
    } else {
        if( $tree->function == OP_RETURN ) {
            my $block = $self->_current_block;
            while( $block ) {
                _exit_scope( $self, $block );
                last if $block->{flags} & CODE_MAIN;
                $block = $block->{outer};
            }
        }

        _add_bytecode $self, opcode_npm( $tree->function, $tree->pos,
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

    _add_bytecode $self,
        opcode_nm( OP_MAKE_LIST, count => 1 + scalar @$args );

    if( $tree->indirect ) {
        _add_bytecode $self,
            opcode_npm( OP_CALL_METHOD_INDIRECT, $tree->pos,
                        context  => _context( $tree ) );
    } else {
        _add_bytecode $self,
            opcode_npm( OP_CALL_METHOD, $tree->pos,
                        context  => _context( $tree ),
                        method   => $tree->method );
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

    _add_bytecode $self,
        opcode_npm( $op, $tree->pos,
                    context   => _context( $tree ) );
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
            _add_bytecode $self,
                opcode_np( $vivify, $tree->pos );
        }

        _add_bytecode $self,
            opcode_npm( $op_save, $left->pos,
                        index => $index,
                        );

        push @{$self->_current_block->{bytecode}},
             [ opcode_npm( $op_rest, $self->_current_block->{pos},
                           index => $index,
                           ),
               ];
    } elsif( $left->isa( 'Language::P::ParseTree::Slice' ) ) {
        die;
    } elsif( $left->isa( 'Language::P::ParseTree::Symbol' ) ) {
        my $index = $self->{_temporary_count}++;
        _add_bytecode $self,
            opcode_npm( OP_LOCALIZE_GLOB_SLOT, $tree->pos,
                        name  => $left->name,
                        slot  => $left->sigil,
                        index => $index,
                        );

        push @{$self->_current_block->{bytecode}},
             [ opcode_npm( OP_RESTORE_GLOB_SLOT, $self->_current_block->{pos},
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
    _pattern( $self, $tree->pattern );

    my $current = $self->_current_basic_block;
    my $block = _new_block( $self );
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
    _add_bytecode $self, opcode_n( OP_STOP );

    $self->_current_basic_block( $current );

    return $block;
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
             opcode_npm( OP_JUMP_IF_TRUE, $tree->pos,
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
                      opcode_npm( $tree->op, $tree->pos,
                                  context => _context( $tree ) );
    } elsif( $tree->op == OP_MATCH || $tree->op == OP_NOT_MATCH ) {
        my $scope_id = $self->_current_block->{id};

        unless( $self->_code_segments->[0]->scopes->[$scope_id]->{flags} & SCOPE_REGEX ) {
            $self->_code_segments->[0]->scopes->[$scope_id]->{flags} |= SCOPE_REGEX;
            push @{$self->_current_block->{bytecode}},
                 [ opcode_nm( OP_RX_STATE_RESTORE, index => $scope_id ) ];
        }

        $self->dispatch( $tree->left );

        if( $tree->right->isa( 'Language::P::ParseTree::Substitution' ) ) {
            my $repl = _substitution( $self, $tree->right );
            my $flags = $tree->right->pattern->flags &
                        (FLAG_RX_GLOBAL|FLAG_RX_KEEP);

            _add_bytecode $self,
                opcode_npm( OP_REPLACE, $tree->pos,
                            context   => _context( $tree ),
                            index     => $scope_id,
                            flags     => $flags,
                            to        => $repl );

            return;
        }

        $self->dispatch( $tree->right );

        my $flags = $tree->right->flags &
                    (FLAG_RX_GLOBAL|FLAG_RX_KEEP);

        _add_bytecode $self,
            opcode_npm( OP_MATCH, $tree->pos,
                        context   => _context( $tree ),
                        flags     => $flags,
                        index     => $scope_id );
        # maybe perform the transformation during parsing, but remember
        # to correctly propagate context
        if( $tree->op == OP_NOT_MATCH ) {
            _add_bytecode $self,
                opcode_npm( OP_LOG_NOT, $tree->pos,
                            context   => _context( $tree ) );
        }
    } else {
        $self->dispatch( $tree->left );
        $self->dispatch( $tree->right );

        _add_bytecode $self,
            opcode_npm( $tree->op, $tree->pos,
                        context   => _context( $tree ) );
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
        opcode_npm( $conditionals{$tree->op}, $tree->pos,
                    true => $true, false => $false ), $true, $false;
}

sub _anything_cond {
    my( $self, $tree, $true, $false ) = @_;

    $self->dispatch( $tree );

    _add_jump $self,
        opcode_npm( OP_JUMP_IF_TRUE, $tree->pos,
                    true => $true, false => $false ), $true, $false;
}

sub _constant {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );
    my $v;

    if( $tree->is_number ) {
        if( $tree->flags & NUM_INTEGER ) {
            _add_bytecode $self,
                 opcode_nm( OP_CONSTANT_INTEGER, value => $tree->value );
        } elsif( $tree->flags & NUM_FLOAT ) {
            _add_bytecode $self,
                 opcode_nm( OP_CONSTANT_FLOAT, value => $tree->value );
        } elsif( $tree->flags & NUM_OCTAL ) {
            _add_bytecode $self,
                 opcode_nm( OP_CONSTANT_INTEGER,
                            value => oct '0' . $tree->value );
        } elsif( $tree->flags & NUM_HEXADECIMAL ) {
            _add_bytecode $self,
                 opcode_nm( OP_CONSTANT_INTEGER,
                            value => oct '0x' . $tree->value );
        } elsif( $tree->flags & NUM_BINARY ) {
            _add_bytecode $self,
                 opcode_nm( OP_CONSTANT_INTEGER,
                            value => oct '0b' . $tree->value );
        } else {
            die "Unhandled flags value";
        }
    } elsif( $tree->is_string ) {
        _add_bytecode $self,
             opcode_nm( OP_CONSTANT_STRING, value => $tree->value );
    } else {
        die "Neither number nor string";
    }
}

sub _symbol {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    _add_bytecode $self,
         opcode_npm( OP_GLOBAL, $tree->pos,
                     name => $tree->name, slot => $tree->sigil );
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

sub _add_value {
    my( $code, $lexical, $index ) = @_;

    return $code->lexicals->{map}{$lexical}{index} = $index;
}

sub _find_add_value {
    my( $code, $lexical ) = @_;
    my $lex = $code->lexicals;

    return $lex->{map}{$lexical}{index}
        if $lex->{map}{$lexical} && $lex->{map}{$lexical}{index} >= 0;
    return $lex->{map}{$lexical}{index} = $lex->{max_pad}++;
}

sub _uplevel {
    my( $code, $level ) = @_;

    $code = $code->outer foreach 1 .. $level;

    return $code;
}

sub _allocate_lexical {
    my( $self, $code, $lexical, $level ) = @_;
    my $lex_info = $code->lexicals->{map}->{$lexical} ||=
        { level       => $level,
          name        => $lexical->name,
          sigil       => $lexical->sigil,
          symbol_name => $lexical->symbol_name,
          index       => -1,
          outer_index => -1,
          in_pad      => $lexical->closed_over ? 1 : 0,
          from_main   => 0,
          };
    return $lex_info if $lex_info->{index} >= 0;

    if(    $lexical->name eq '_'
        && $lexical->sigil == VALUE_ARRAY ) {
        $lex_info->{index} = 0; # arguments are always first
    } elsif( $lexical->closed_over ) {
        my $level = $lex_info->{level};
        if( $level ) {
            my $code_from = _uplevel( $code, $level );
            my $val = _allocate_lexical( $self, $code_from,
                                         $lexical, 0 )->{index};
            if( $code_from->is_sub ) {
                my $outer = $code->outer;
                _allocate_lexical( $self, $outer, $lexical, $level - 1 );
                $lex_info->{index} = _find_add_value( $code, $lexical );
                $lex_info->{outer_index} = _find_add_value( $outer, $lexical );
            } else {
                $lex_info->{index} = _find_add_value( $code, $lexical );
                $lex_info->{outer_index} = $val;
                $lex_info->{from_main} = 1;
            }
        } else {
            $lex_info->{index} = _find_add_value( $code, $lexical );
        }
    } else {
        $lex_info->{index} = $code->lexicals->{max_stack}++;
    }

    return  $lex_info;
}

sub _do_lexical_access {
    my( $self, $tree, $level, $is_decl ) = @_;

    # maybe do it while parsing, in _find_symbol/_process_lexical_declaration
    my $lex_info = $self->_code_segments->[0]->lexicals->{map}->{$tree};
    if( !$lex_info || $lex_info->{index} < 0 ) {
        $lex_info = _allocate_lexical( $self, $self->_code_segments->[0],
                                       $tree, $level );
    }

    _add_bytecode $self,
         opcode_nm( $lex_info->{in_pad} ? OP_LEXICAL_PAD : OP_LEXICAL,
                    index => $lex_info->{index},
                    slot  => $tree->sigil,
                    );

    if( $is_decl ) {
        $lex_info->{declaration} = 1;

        push @{$self->_current_block->{bytecode}},
             [ opcode_npm( $lex_info->{in_pad} ? OP_LEXICAL_PAD_CLEAR : OP_LEXICAL_CLEAR,
                           $self->_current_block->{pos},
                           index => $lex_info->{index},
                           slot  => $tree->sigil,
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
        _add_jump $self, opcode_nm( OP_JUMP, to => $start_continue ), $start_continue;

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

sub _foreach {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $iter_var = $tree->variable;
    my $is_lexical = $iter_var->isa( 'Language::P::ParseTree::LexicalDeclaration' );

    my( $start_step, $start_loop, $start_continue, $exit_loop, $end_loop ) =
        _new_blocks( $self, 5 );
    $tree->set_attribute( 'lbl_next', $tree->continue ? $start_continue :
                                                        $start_step );
    $tree->set_attribute( 'lbl_last', $end_loop );
    $tree->set_attribute( 'lbl_redo', $start_loop );

    if( $tree->block->isa( 'Language::P::ParseTree::Block' ) ) {
        _start_bb( $self );
        $self->push_block( 0, $tree->pos_s, $tree->pos_e );
    }

    $self->dispatch( $tree->expression );
    _add_bytecode $self, opcode_nm( OP_MAKE_LIST, count => 1 );

    my $iterator = $self->{_temporary_count}++;
    my( $glob, $slot );
    _add_bytecode $self,
        opcode_npm( OP_ITERATOR, $tree->pos ),
        opcode_nm( OP_TEMPORARY_SET,
                   index => $iterator,
                   slot  => VALUE_ITERATOR );

    if( !$is_lexical ) {
        $glob = $self->{_temporary_count}++;
        $slot = $self->{_temporary_count}++;

        _add_bytecode $self,
            opcode_nm( OP_GLOBAL, name => $iter_var->name, slot => VALUE_GLOB ),
            opcode_n( OP_DUP ),
            opcode_nm( OP_GLOB_SLOT,   slot  => VALUE_SCALAR ),
            opcode_nm( OP_TEMPORARY_SET,
                       index => $slot,
                       slot  => VALUE_SCALAR ),
            opcode_nm( OP_TEMPORARY_SET,
                       index => $glob,
                       slot  => VALUE_GLOB );

        push @{$self->_current_block->{bytecode}},
             [ opcode_npm( OP_TEMPORARY, $self->_current_block->{pos},
                           index => $glob,
                           slot  => VALUE_GLOB ),
               opcode_npm( OP_TEMPORARY, $self->_current_block->{pos},
                           index => $slot,
                           slot  => VALUE_SCALAR ),
               opcode_npm( OP_GLOB_SLOT_SET, $self->_current_block->{pos},
                           slot  => VALUE_SCALAR ),
               ];
    }

    _add_jump $self, opcode_nm( OP_JUMP, to => $start_step ), $start_step;
    _add_blocks $self, $start_step;

    if( !$is_lexical ) {
        _add_bytecode $self,
            opcode_nm( OP_TEMPORARY,
                       index => $iterator,
                       slot  => VALUE_ITERATOR ),
            opcode_npm( OP_ITERATOR_NEXT, $tree->pos ),
            opcode_n( OP_DUP );
        _add_jump $self,
            opcode_npm( OP_JUMP_IF_NULL, $tree->pos,
                        true => $exit_loop, false => $start_loop ),
            $exit_loop, $start_loop;

        _add_blocks $self, $start_loop;
        _add_bytecode $self,
            opcode_nm( OP_TEMPORARY,
                       index => $glob,
                       slot  => VALUE_GLOB ),
            opcode_n( OP_SWAP ),
            opcode_nm( OP_GLOB_SLOT_SET, slot  => VALUE_SCALAR );
    } else {
        _add_bytecode $self,
            opcode_nm( OP_TEMPORARY,
                       index => $iterator,
                       slot  => VALUE_ITERATOR ),
            opcode_np( OP_ITERATOR_NEXT, $tree->pos ),
            opcode_n( OP_DUP );
        _add_jump $self,
            opcode_npm( OP_JUMP_IF_NULL, $tree->pos,
                        true => $exit_loop, false => $start_loop ),
            $exit_loop, $start_loop;

        _add_blocks $self, $start_loop;
        _allocate_lexical( $self, $self->_code_segments->[0], $iter_var, 0 );
        my $lex_info = $self->_code_segments->[0]->lexicals->{map}->{$iter_var};
        _add_bytecode $self,
            opcode_nm( $iter_var->closed_over ? OP_LEXICAL_PAD_SET : OP_LEXICAL_SET,
                       index => $lex_info->{index},
                       );
    }

    $self->dispatch( $tree->block );
    _discard_if_void( $self, $tree->block );

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

    if( $tree->block->isa( 'Language::P::ParseTree::Block' ) ) {
        _exit_scope( $self, $self->_current_block );
        $self->pop_block;
        _start_bb( $self );
    }
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

    $self->dispatch( $tree->initializer );
    _discard_if_void( $self, $tree->initializer );

    _add_jump $self,
         opcode_nm( OP_JUMP, to => $start_cond ), $start_cond;
    _add_blocks $self, $start_cond;

    $self->dispatch_cond( $tree->condition, $start_loop, $end_loop );

    _add_blocks $self, $start_loop;
    $self->dispatch( $tree->block );
    _discard_if_void( $self, $tree->block );

    _add_jump $self,
         opcode_nm( OP_JUMP, to => $start_step ), $start_step;

    _add_blocks $self, $start_step;
    $self->dispatch( $tree->step );
    _discard_if_void( $self, $tree->step );
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

    if( $with_scope ) {
        _start_bb( $self );
        $self->push_block( 0, $tree->pos_s, $tree->pos_e );
    }

    my( $next, $last ) = _new_blocks( $self, 2 );
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
    _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;

    _add_blocks $self, $false;
    $self->dispatch( $tree->iffalse );
    _add_jump $self, opcode_nm( OP_JUMP, to => $end ), $end;

    _add_blocks $self, $end;
}

sub _emit_lexical_state {
    my( $self, $tree ) = @_;

    if( $tree->get_attribute( 'lexical_state' ) ) {
        my $scope_id = $self->_current_block->{id};
        my $lex_state = $self->_code_segments->[0]->scopes->[$scope_id]->{lexical_state};

        _add_bytecode $self,
            opcode_nm( OP_LEXICAL_STATE_SAVE, index => $lex_state );
        push @{$self->_current_block->{bytecode}},
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

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
        _discard_if_void( $self, $line );
    }

    _exit_scope( $self, $self->_current_block );
    $self->pop_block;
    _start_bb( $self ) if $is_eval;
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
        opcode_nm( OP_CONSTANT_SUB, value => $sub ),
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
                            } );
    my $code_segments = $generator->generate_use( $tree );
    push @{$self->_code_segments}, @$code_segments;

    return $code_segments->[0];
}

sub _quoted_string {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    if( @{$tree->components} == 1 ) {
        $self->dispatch( $tree->components->[0] );

        _add_bytecode $self,
            opcode_npm( OP_STRINGIFY, $tree->pos,
                        context   => _context( $tree ) );

        return;
    }

    _add_bytecode $self, opcode_nm( OP_FRESH_STRING, value => '' );
    for( my $i = 0; $i < @{$tree->components}; ++$i ) {
        my $c = $tree->components->[$i];
        if(    ( $c->is_symbol && $c->sigil == VALUE_ARRAY )
            || (    $c->isa( 'Language::P::ParseTree::Dereference' )
                 && $c->op == OP_DEREFERENCE_ARRAY ) ) {
            _add_bytecode $self,
                opcode_npm( OP_GLOBAL, $tree->pos,
                            name => '"', slot => VALUE_SCALAR );
            $self->dispatch( $c );
            _add_bytecode $self,
                opcode_nm( OP_MAKE_LIST, count => 2 ),
                opcode_npm( OP_JOIN, $tree->pos );
        } else {
            $self->dispatch( $c );
        }

        _add_bytecode $self, opcode_npm( OP_CONCATENATE_ASSIGN, $tree->pos,
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
        _add_bytecode $self, opcode_npm( OP_VIVIFY_ARRAY, $tree->pos,
                                         context   => CXT_SCALAR )
          if $tree->reference;
        _add_bytecode $self, opcode_npm( OP_ARRAY_ELEMENT, $tree->pos,
                                         create    => $lvalue ? 1 : 0,
                                         context   => _context( $tree ) );
    } elsif( $tree->type == VALUE_HASH ) {
        _add_bytecode $self, opcode_npm( OP_VIVIFY_HASH, $tree->pos,
                                         context   => CXT_SCALAR )
          if $tree->reference;
        _add_bytecode $self, opcode_npm( OP_HASH_ELEMENT, $tree->pos,
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
        _add_bytecode $self, opcode_npm( OP_ARRAY_SLICE, $tree->pos,
                                         create    => $lvalue ? 1 : 0,
                                         context   => _context( $tree ) );
    } elsif( $tree->type == VALUE_HASH ) {
        _add_bytecode $self, opcode_npm( OP_HASH_SLICE, $tree->pos,
                                         create    => $lvalue ? 1 : 0,
                                         context   => _context( $tree ) );
    } elsif( $tree->type == VALUE_LIST ) {
        _add_bytecode $self, opcode_npm( OP_LIST_SLICE, $tree->pos,
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
        _add_bytecode $self, opcode_nm( OP_MAKE_LIST, count => 0 );
    }

    if( $tree->type == VALUE_ARRAY ) {
        _add_bytecode $self, opcode_np( OP_ANONYMOUS_ARRAY, $tree->pos );
    } elsif( $tree->type == VALUE_HASH ) {
        _add_bytecode $self, opcode_np( OP_ANONYMOUS_HASH, $tree->pos );
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
    return if $tree->always_void;
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
    _add_bytecode $self, opcode_nm( OP_CONSTANT_REGEX, value => $re->[0] );
}

sub _interpolated_pattern {
    my( $self, $tree ) = @_;

    $self->dispatch( $tree->string );

    _add_bytecode $self, opcode_npm( OP_EVAL_REGEX, $tree->pos,
                                     context => _context( $tree ),
                                     flags   => $tree->flags,
                                     );
}

sub _exit_scope {
    my( $self, $block ) = @_;

    foreach my $code ( reverse @{$block->{bytecode}} ) {
        _add_bytecode $self, @$code;
    }
}

my %regex_assertions =
  ( BEGINNING        => OP_RX_BEGINNING,
    END_OR_NEWLINE   => OP_RX_END_OR_NEWLINE,
    ANY_NONEWLINE    => OP_RX_ANY_NONEWLINE,
    ANY              => OP_RX_ANY,
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

    _add_bytecode $self,
        opcode_nm( OP_RX_EXACT, string => $tree->value,
                   length => length( $tree->value ) );
}

sub _regex_class {
    my( $self, $tree ) = @_;

    my @elements;
    foreach my $e ( @{$tree->elements} ) {
        push @elements,
             opcode_nm( OP_RX_EXACT, string => $e->value,
                        length => length( $e->value ) );
    }

    if( @elements == 1 ) {
        _add_bytecode $self, $elements[0];
    } else {
        _add_bytecode $self,
            opcode_nm( OP_RX_CLASS,
                       elements => \@elements );
    }
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
