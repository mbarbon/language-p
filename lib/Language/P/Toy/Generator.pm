package Language::P::Toy::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_ro_accessors( qw(runtime) );
__PACKAGE__->mk_accessors( qw(_propagate_context) );

use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::StringNumber;
use Language::P::Toy::Value::Handle;
use Language::P::Toy::Value::ScratchPad;
use Language::P::Toy::Value::Code;
use Language::P::Toy::Value::Regex;
use Language::P::ParseTree::PropagateContext;
use Language::P::ParseTree qw(:all);
use Language::P::Keywords qw(:all);

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->_propagate_context( Language::P::ParseTree::PropagateContext->new );

    return $self;
}

# global on purpose
our %debug_options;

sub set_debug {
    my( $class, $option, $value ) = @_;

    $debug_options{$option} = defined $value ? $value : 1;
}

# HACK
our @bytecode;
our %labels;
our %patch;
our $label_count = 0;
our $group_count;

sub _new_label {
    ++$label_count;
    $labels{$label_count} = undef;

    return $label_count;
}

sub _set_label {
    my( $label, $to ) = @_;

    die if $labels{$label};
    $labels{$label} = $to;

    $_->{to} = $to foreach @{$patch{$label} || []};
    delete $patch{$label};
}

sub _to_label {
    my( $label, $op ) = @_;

    $op->{to} = $labels{$label} if $labels{$label};
    push @{$patch{$label} ||= []}, $op;
}

my @code_stack;

sub push_code {
    my( $self, $code ) = @_;

    my $pad = Language::P::Toy::Value::ScratchPad->new;
    push @code_stack, [ $code, [], $pad ];

    # TODO do not use global
    *bytecode = $code->bytecode;
}

sub pop_code {
    my( $self ) = @_;

    my $code = pop @code_stack;

    # TODO do not use global
    *bytecode = @code_stack ? $code_stack[-1][0]->bytecode : [];

    return $code->[0];
}

our $current_block;

sub push_block {
    my( $self, $is_sub ) = @_;

    $current_block =
      { outer    => $current_block,
        is_sub   => $is_sub || 0,
        bytecode => [],
        };

    return $current_block;
}

sub pop_block {
    my( $self ) = @_;
    my $to_ret = $current_block;

    $current_block = $current_block->{outer};

    return $to_ret;
}

sub process {
    my( $self, $tree ) = @_;

    $self->_propagate_context->visit( $tree, CXT_VOID );
    push @{$code_stack[-1][1]}, $tree;

    return;
}

sub process_pending {
    my( $self ) = @_;

    my $dump_yaml;
    if( $debug_options{parse_tree} ) {
        require Language::P::ParseTree::DumpYAML;
        $dump_yaml = Language::P::ParseTree::DumpYAML->new;
    }

    foreach my $tree ( @{$code_stack[-1][1]} ) {
        if( $debug_options{parse_tree} ) {
            print STDERR $dump_yaml->dump( $tree );
        }

        $self->dispatch( $tree );
    }
    $code_stack[-1][1] = []
}

sub process_regex {
    my( $self, $regex ) = @_;
    my $rx = Language::P::Toy::Value::Regex->new
                 ( { bytecode   => [],
                     stack_size => 0,
                     } );
    $group_count = 0;

    $self->push_code( $rx );

    push @bytecode, o( 'rx_start_match' );

    foreach my $e ( @{$regex->components} ) {
        $self->dispatch_regex( $e );
    }

    push @bytecode, o( 'rx_accept', groups => $group_count );

    $self->pop_code;

    die "Flags not supported" if $regex->flags;

    return $rx;
}

sub add_declaration {
    my( $self, $name ) = @_;

    my $sub = Language::P::Toy::Value::Subroutine::Stub->new
                  ( { name     => $name,
                      } );
    $self->runtime->symbol_table->set_symbol( $name, '&', $sub );
}

sub finished {
    my( $self ) = @_;

    my $is_sub = $code_stack[-1][0]->isa( 'Language::P::Toy::Value::Subroutine' );
    $self->process_pending;
    $self->_allocate_lexicals( $is_sub );

    if( $is_sub ) {
        # could be avoided in most cases, but simplifies code generation
        push @bytecode,
            o( 'start_list' ),
            o( 'end_list' ),
            o( 'return' );
    } else {
        push @bytecode, o( 'end' );
    }
}

sub start_code_generation {
    my( $self ) = @_;

    my $code = Language::P::Toy::Value::Code->new( { bytecode => [] } );
    $self->push_code( $code );
    $self->push_block;

    return $code;
}

sub end_code_generation {
    my( $self ) = @_;

    $self->finished;
    $self->pop_block;
    return $self->pop_code;
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

my %sigil_to_slot =
  ( VALUE_SCALAR() => 'scalar',
    VALUE_SUB()    => 'subroutine',
    VALUE_ARRAY()  => 'array',
    );

my %conditionals =
  ( OP_NUM_LT() => 'compare_f_lt_int',
    OP_STR_LT() => 'compare_s_lt_int',
    OP_NUM_GT() => 'compare_f_gt_int',
    OP_STR_GT() => 'compare_s_gt_int',
    OP_NUM_LE() => 'compare_f_le_int',
    OP_STR_LE() => 'compare_s_le_int',
    OP_NUM_GE() => 'compare_f_ge_int',
    OP_STR_GE() => 'compare_s_ge_int',
    OP_NUM_EQ() => 'compare_f_eq_int',
    OP_STR_EQ() => 'compare_s_eq_int',
    OP_NUM_NE() => 'compare_f_ne_int',
    OP_STR_NE() => 'compare_s_ne_int',
    );

my %short_circuit =
  ( OP_LOG_AND() => 'jump_if_false',
    OP_LOG_OR()  => 'jump_if_true',
    );

my %unary =
  ( OP_MINUS()           => 'negate',
    OP_LOG_NOT()         => 'not',
    OP_REFERENCE()       => 'reference',
    VALUE_SCALAR()       => 'dereference_scalar',
    VALUE_SUB()          => 'dereference_subroutine',
    VALUE_ARRAY_LENGTH() => 'array_size',
    OP_BACKTICK()        => 'backtick',
    );

my %builtins =
  ( print    => 'print',
    return   => 'return',
    unlink   => 'unlink',
    %short_circuit,
    OP_CONCATENATE()            => 'concat',
    OP_ADD()                    => 'add',
    OP_MULTIPLY()               => 'multiply',
    OP_SUBTRACT()               => 'subtract',
    OP_MATCH()                  => 'rx_match',
    OP_ASSIGN()                 => 'assign',
    OP_NUM_LE()                 => 'compare_f_le_scalar',
    OP_STR_LE()                 => 'compare_s_le_scalar',
    OP_NUM_EQ()                 => 'compare_f_eq_scalar',
    OP_STR_EQ()                 => 'compare_s_eq_scalar',
    OP_NUM_NE()                 => 'compare_f_ne_scalar',
    OP_STR_NE()                 => 'compare_s_ne_scalar',
    );

my %builtins_no_list =
  ( abs      => 'abs',
    defined  => 'defined',
    undef    => 'undef',
    wantarray=> 'want',
    );

sub _indirect {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    push @bytecode, o( 'start_list' );

    if( $tree->indirect ) {
        $self->dispatch( $tree->indirect );
    } else {
        my $out = Language::P::Toy::Value::Handle->new( { handle => \*STDOUT } );
        push @bytecode, o( 'constant', value => $out );
    }

    foreach my $arg ( @{$tree->arguments} ) {
        $self->dispatch( $arg );
    }

    push @bytecode, o( 'end_list' ), o( $builtins{$tree->function} );
}

sub _builtin {
    my( $self, $tree ) = @_;

    if( $tree->function eq 'undef' && !$tree->arguments ) {
        _emit_label( $self, $tree );
        push @bytecode, o( 'constant',
                           value => Language::P::Toy::Value::StringNumber->new );
    } elsif( $builtins_no_list{$tree->function} ) {
        _emit_label( $self, $tree );
        foreach my $arg ( @{$tree->arguments || []} ) {
            $self->dispatch( $arg );
        }

        push @bytecode, o( $builtins_no_list{$tree->function} );
    } else {
        return _function_call( $self, $tree );
    }
}

sub _function_call {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    push @bytecode, o( 'start_list' );

    foreach my $arg ( @{$tree->arguments || []} ) {
        $self->dispatch( $arg );
    }

    push @bytecode, o( 'end_list' );

    Carp::confess( "Unknown '" . $tree->function . "'" )
        unless ref( $tree->function ) || $builtins{$tree->function};

    if( ref( $tree->function ) ) {
        $self->dispatch( $tree->function );
        push @bytecode, o( 'call', context => $tree->get_attribute( 'context' ) & CXT_CALL_MASK );
    } else {
        if( $tree->function eq 'return' ) {
            my $block = $current_block;
            while( $block ) {
                _exit_scope( $self, $block );
                last if $block->{is_sub};
                $block = $block->{outer};
            }
        }
        push @bytecode, o( $builtins{$tree->function} );
    }
}

sub _list {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    push @bytecode, o( 'start_list' );

    foreach my $arg ( @{$tree->expressions} ) {
        $self->dispatch( $arg );
    }

    push @bytecode, o( 'end_list' );
}

sub _unary_op {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    die $tree->op unless $unary{$tree->op};

    $self->dispatch( $tree->left );

    push @bytecode, o( $unary{$tree->op} );
}

sub _local {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    die "Can only localize global for now"
        unless $tree->left->isa( 'Language::P::ParseTree::Symbol' );

    my $index = $code_stack[-1][0]->stack_size;
    ++$code_stack[-1][0]->{stack_size};

    my $slot = $sigil_to_slot{$tree->left->sigil};
    push @bytecode,
         o( 'localize_glob_slot',
            name  => $tree->left->name,
            slot  => $slot,
            index => $index,
            );

    push @{$current_block->{bytecode}},
         [ o( 'restore_glob_slot',
              name  => $tree->left->name,
              slot  => $slot,
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

    die $tree->op unless $builtins{$tree->op};

    if( $short_circuit{$tree->op} ) {
        $self->dispatch( $tree->left );

        my $end = _new_label;

        # jump to $end if evalutating right is not necessary
        push @bytecode,
             o( 'dup' ),
             o( $short_circuit{$tree->op} ),
             o( 'pop' );
        _to_label( $end, $bytecode[-2] );

        # evalutates right only if this is the correct return value
        $self->dispatch( $tree->right );

        _set_label( $end, scalar @bytecode );
    } else {
        $self->dispatch( $tree->right );
        $self->dispatch( $tree->left );

        push @bytecode, o( $builtins{$tree->op} );
    }
}

sub _binary_op_cond {
    my( $self, $tree, $true, $false ) = @_;

    if( !$conditionals{$tree->op} ) {
        _anything_cond( $self, $tree, $true, $false );

        return;
    }

    _emit_label( $self, $tree );
    $self->dispatch( $tree->right );
    $self->dispatch( $tree->left );

    push @bytecode, o( $conditionals{$tree->op} );
    # jump to $false if false, fall trough if true
    push @bytecode, o( 'jump_if_eq_immed', value => 0 );
    _to_label( $false, $bytecode[-1] );
}

sub _anything_cond {
    my( $self, $tree, $true, $false ) = @_;

    $self->dispatch( $tree );

    # jump to $false if false, fall trough if true
    push @bytecode, o( 'jump_if_false' );
    _to_label( $false, $bytecode[-1] );
}

sub _constant {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );
    my $v;

    if( $tree->is_number ) {
        if( $tree->flags & NUM_INTEGER ) {
            $v = Language::P::Toy::Value::StringNumber
                     ->new( { integer => $tree->value } );
        } elsif( $tree->flags & NUM_FLOAT ) {
            $v = Language::P::Toy::Value::StringNumber
                     ->new( { float => $tree->value } );
        } elsif( $tree->flags & NUM_OCTAL ) {
            $v = Language::P::Toy::Value::StringNumber
                     ->new( { integer => oct '0' . $tree->value } );
        } elsif( $tree->flags & NUM_HEXADECIMAL ) {
            $v = Language::P::Toy::Value::StringNumber
                     ->new( { integer => oct '0x' . $tree->value } );
        } elsif( $tree->flags & NUM_BINARY ) {
            $v = Language::P::Toy::Value::StringNumber
                     ->new( { integer => oct '0b' . $tree->value } );
        } else {
            die "Unhandled flags value";
        }
    } elsif( $tree->is_string ) {
        $v = Language::P::Toy::Value::StringNumber->new( { string => $tree->value } );
    } else {
        die "Neither number nor string";
    }

    push @bytecode, o( 'constant', value => $v );
}

sub _symbol {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    if( $tree->sigil == VALUE_GLOB ) {
        push @bytecode, o( 'glob', name => $tree->name, create => 1 );
        return;
    }

    my $slot = $sigil_to_slot{$tree->sigil};
    die $tree->sigil unless $slot;

    push @bytecode,
         o( 'glob',             name => $tree->name, create => 1 ),
         o( 'glob_slot_create', slot => $slot );
}

sub _lexical_symbol {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    _do_lexical_access( $self, $tree->declaration, 0 );
    $bytecode[-1]->{level} = $tree->level;
}

sub _lexical_declaration {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    _do_lexical_access( $self, $tree, 1 );
}

sub _do_lexical_access {
    my( $self, $tree, $is_decl ) = @_;

    my $in_pad = $tree->closed_over;
    push @bytecode,
        o( $in_pad ? 'lexical_pad' : 'lexical',
           lexical  => $tree,
           level    => 0,
           );

    if( $is_decl ) {
        push @{$current_block->{bytecode}},
             [ o( $in_pad ? 'lexical_pad_clear' : 'lexical_clear',
                  lexical => $tree,
                  level   => 0,
                  ),
               ];
    }
}

sub _cond_loop {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $is_until = $tree->block_type eq 'until';
    my( $start_cond, $start_loop, $start_continue, $end_loop ) =
      ( _new_label, _new_label, _new_label, _new_label );
    $tree->set_attribute( 'toy_next', $tree->continue ? $start_continue :
                                                        $start_cond );
    $tree->set_attribute( 'toy_last', $end_loop );
    $tree->set_attribute( 'toy_redo', $start_loop );
    _set_label( $start_cond, scalar @bytecode );

    $self->dispatch_cond( $tree->condition,
                          $is_until ? ( $end_loop, $start_loop ) :
                                      ( $start_loop, $end_loop ) );
    _set_label( $start_loop, scalar @bytecode );
    $self->dispatch( $tree->block );
    _set_label( $start_continue, scalar @bytecode );
    $self->dispatch( $tree->continue ) if $tree->continue;
    push @bytecode, o( 'jump' );
    _to_label( $start_cond, $bytecode[-1] );
    _set_label( $end_loop, scalar @bytecode );
}

sub _foreach {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $is_lexical = $tree->variable->isa( 'Language::P::ParseTree::LexicalDeclaration' );

    my( $start_step, $start_loop, $start_continue, $end_loop ) =
      ( _new_label, _new_label, _new_label, _new_label );
    $tree->set_attribute( 'toy_next', $tree->continue ? $start_continue :
                                                        $start_step );
    $tree->set_attribute( 'toy_last', $end_loop );
    $tree->set_attribute( 'toy_redo', $start_loop );

    my $iter_index = $code_stack[-1][0]->stack_size;
    my $var_index = $code_stack[-1][0]->stack_size + 1;
    my $old_value;
    $code_stack[-1][0]->{stack_size} += 2;

    if( $is_lexical ) {
        _add_value( $code_stack[-1][2], $tree->variable, $var_index );
    }

    push @bytecode, o( 'start_list' );
    $self->dispatch( $tree->expression );
    push @bytecode, o( 'end_list' );

    push @bytecode,
        o( 'iterator' ),
        o( 'lexical_set', index => $iter_index );

    if( !$is_lexical ) {
        $old_value = $code_stack[-1][0]->stack_size;
        ++$code_stack[-1][0]->{stack_size};

        push @bytecode,
            o( 'glob',        name  => $tree->variable->name, create => 1 ),
            o( 'dup' ),
            o( 'glob_slot',   slot  => 'scalar' ),
            o( 'lexical_set', index => $old_value ),
            o( 'lexical_set', index => $var_index );

        push @{$current_block->{bytecode}},
             [ o( 'lexical',       index => $var_index ),
               o( 'lexical',       index => $old_value ),
               o( 'glob_slot_set', slot  => 'scalar' ),
               ];
    }

    _set_label( $start_step, scalar @bytecode );

    if( !$is_lexical ) {
        push @bytecode,
            o( 'lexical',       index => $iter_index ),
            o( 'iterator_next' ),
            o( 'dup' ),
            o( 'jump_if_undef' ),
            o( 'lexical',       index => $var_index ),
            o( 'swap' ),
            o( 'glob_slot_set', slot  => 'scalar' );

        _to_label( $end_loop, $bytecode[-4] );
    } else {
        push @bytecode,
            o( 'lexical',      index => $iter_index ),
            o( 'iterator_next' ),
            o( 'dup' ),
            o( 'jump_if_undef' ),
            o( 'lexical_set',  index => $var_index );

        _to_label( $end_loop, $bytecode[-2] );
    }

    _set_label( $start_loop, scalar @bytecode );

    $self->dispatch( $tree->block );
    _set_label( $start_continue, scalar @bytecode );
    $self->dispatch( $tree->continue ) if $tree->continue;
    push @bytecode, o( 'jump' );
    _to_label( $start_step, $bytecode[-1] );
    _set_label( $end_loop, scalar @bytecode );
}

sub _for {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my( $start_cond, $start_loop, $start_step, $end_loop ) =
      ( _new_label, _new_label, _new_label, _new_label );
    $tree->set_attribute( 'toy_next', $start_step );
    $tree->set_attribute( 'toy_last', $end_loop );
    $tree->set_attribute( 'toy_redo', $start_loop );

    $self->dispatch( $tree->initializer );

    _set_label( $start_cond, scalar @bytecode );

    $self->dispatch_cond( $tree->condition, $start_loop, $end_loop );
    _set_label( $start_loop, scalar @bytecode );
    $self->dispatch( $tree->block );
    _set_label( $start_step, scalar @bytecode );
    $self->dispatch( $tree->step );
    push @bytecode, o( 'jump' );
    _to_label( $start_cond, $bytecode[-1] );
    _set_label( $end_loop, scalar @bytecode );
}

sub _cond {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $end_cond = _new_label;
    foreach my $elsif ( @{$tree->iftrues} ) {
        my $is_unless = $elsif->block_type eq 'unless';
        my( $then_block, $else_block ) = ( _new_label, _new_label );
        $self->dispatch_cond( $elsif->condition,
                              $is_unless ? ( $else_block, $then_block ) :
                                           ( $then_block, $else_block ) );
        _set_label( $then_block, scalar @bytecode );
        $self->dispatch( $elsif->block );
        push @bytecode, o( 'jump' );
        _to_label( $end_cond, $bytecode[-1] );
        _set_label( $else_block, scalar @bytecode );
    }
    if( $tree->iffalse ) {
        $self->dispatch( $tree->iffalse->block );
    }
    _set_label( $end_cond, scalar @bytecode );
}

sub _ternary {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my( $end, $true, $false ) = ( _new_label, _new_label, _new_label );
    $self->dispatch_cond( $tree->condition, $true, $false );
    _set_label( $true, scalar @bytecode );
    $self->dispatch( $tree->iftrue );
    push @bytecode, o( 'jump' );
    _to_label( $end, $bytecode[-1] );
    _set_label( $false, scalar @bytecode );

    $self->dispatch( $tree->iffalse );

    _set_label( $end, scalar @bytecode );
}

sub _block {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    $self->push_block;

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
    }

    _exit_scope( $self, $current_block );
    $self->pop_block;
}

sub _subroutine_decl {
    my( $self, $tree ) = @_;

    # nothing to do
}

sub _anon_subroutine {
    my( $self, $tree ) = @_;
    my $sub = _subroutine( $self, $tree );

    push @bytecode,
        o( 'constant', value => $sub ),
        o( 'make_closure' );
}

sub _subroutine {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    my $sub = Language::P::Toy::Value::Subroutine->new
                  ( { bytecode => [],
                      name     => $tree->name,
                      } );
    $self->push_code( $sub );
    $self->push_block( 1 );

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
    }

    $self->finished;
    $self->pop_block;
    $self->pop_code;

    $self->runtime->symbol_table->set_symbol( $tree->name, '&', $sub )
      if defined $tree->name;

    return $sub;
}

sub _quoted_string {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    if( @{$tree->components} == 1 ) {
        $self->dispatch( $tree->components->[0] );

        push @bytecode, o( 'stringify' );

        return;
    }

    $self->dispatch( $tree->components->[-1] );
    for( my $i = @{$tree->components} - 2; $i >= 0; --$i ) {
        $self->dispatch( $tree->components->[$i] );

        push @bytecode, o( 'concat' );
    }
}

sub _subscript {
    my( $self, $tree ) = @_;
    _emit_label( $self, $tree );

    die if $tree->reference;

    $self->dispatch( $tree->subscript );
    $self->dispatch( $tree->subscripted );

    if( $tree->type == VALUE_ARRAY ) {
        push @bytecode, o( 'array_element' );
    } elsif( $tree->type == VALUE_HASH ) {
        push @bytecode, o( 'hash_element' );
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
        ++$level if $node->isa( 'Language::P::ParseTree::Block' );
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

    my $block = $current_block;
    foreach ( 1 .. $level ) {
        _exit_scope( $self, $block );
        $block = $block->{outer};
    }

    my $label_to;
    if( $tree->op == OP_GOTO ) {
        $label_to = $target->get_attribute( 'toy_label' );
        if( !$label_to ) {
            $target->set_attribute( 'toy_label', $label_to = _new_label );
        }
    } else {
        my $label = $tree->op == OP_NEXT ? 'toy_next' :
                    $tree->op == OP_LAST ? 'toy_last' :
                                           'toy_redo';
        $label_to = $target->get_attribute( $label )
            or die "Missing loop control label";
    }

    push @bytecode, o( 'jump' );
    _to_label( $label_to, $bytecode[-1] );
}

sub _emit_label {
    my( $self, $tree ) = @_;
    return unless $tree->has_attribute( 'label' );

    if( $tree->has_attribute( 'toy_label' ) ) {
        _set_label( $tree->get_attribute( 'toy_label' ), scalar @bytecode );
    } else {
        my $label_to = _new_label;
        _set_label( $label_to, scalar @bytecode );
        $tree->set_attribute( 'toy_label', $label_to );
    }
}

sub _pattern {
    my( $self, $tree ) = @_;

    my $re = $self->process_regex( $tree );
    push @bytecode, o( 'constant', value => $re );
}

my %lex_map;

sub _find_add_value {
    my( $pad, $lexical ) = @_;

    return $lex_map{$pad}{$lexical} if exists $lex_map{$pad}{$lexical};
    return $lex_map{$pad}{$lexical} = $pad->add_value( $lexical );
}

sub _add_value {
    my( $pad, $lexical, $index ) = @_;

    $lex_map{$pad}{$lexical} = $index;
}

sub _allocate_lexicals {
    my( $self, $is_sub ) = @_;

    my $pad = $code_stack[-1][2];
    my %map = $lex_map{$pad} ? %{ delete $lex_map{$pad} } : ();
    my %clear;
    my $has_pad;
    foreach my $op ( @bytecode ) {
        next if !$op->{lexical};

        if( !exists $map{$op->{lexical}} ) {
            if(    $op->{lexical}->name eq '_'
                && $op->{lexical}->sigil == VALUE_ARRAY ) {
                $map{$op->{lexical}} = 0; # arguments are always first
            } elsif( $op->{lexical}->closed_over ) {
                if( $op->{level} ) {
                    my $code_from = $code_stack[-1 - $op->{level}][0];
                    my $pad_from = $code_stack[-1 - $op->{level}][2];
                    my $val = _find_add_value( $pad_from, $op->{lexical} );
                    if( $code_from->is_subroutine ) {
                        foreach my $index ( -$op->{level} .. -1 ) {
                            my $outer_pad = $code_stack[$index - 1][2];
                            my $inner_pad = $code_stack[$index][2];

                            my $outer_idx = _find_add_value( $outer_pad, $op->{lexical} );
                            my $inner_idx = _find_add_value( $inner_pad, $op->{lexical} );
                            push @{$code_stack[$index][0]->closed},
                              [$outer_idx, $inner_idx];
                            $map{$op->{lexical}} = $inner_idx
                              if $index == -1;
                        }
                    } else {
                        $map{$op->{lexical}} =
                            $pad->add_value( $op->{lexical},
                                             $pad_from->values->[ $val ] );
                    }
                } else {
                    $map{$op->{lexical}} = _find_add_value( $pad, $op->{lexical} );
                }
            } else {
                $map{$op->{lexical}} = $code_stack[-1][0]->stack_size;
                ++$code_stack[-1][0]->{stack_size};
            }
        }

        if( !$has_pad && $op->{lexical}->closed_over ) {
            $code_stack[-1][0]->{lexicals} = $pad;
            $pad->{outer} = $code_stack[-1][0]->{outer};
            $has_pad = 1;
        }
        $op->{in_pad} = $op->{lexical}->closed_over;
        $op->{index} = $map{$op->{lexical}};
        $clear{$op->{index}} ||= 1 if $op->{in_pad} && !$op->{level};
        delete $op->{lexical};
        delete $op->{level};
    }

    $code_stack[-1][0]->{closed} = undef unless @{$code_stack[-1][0]->closed};
    if( !$has_pad && $code_stack[-1][0]->closed ) {
        $code_stack[-1][0]->{lexicals} = $pad;
        # FIXME accessors
        $pad->{outer} = $code_stack[-1][0]->{outer};
    }
    $pad->{clear} = [ keys %clear ];
}

sub _exit_scope {
    my( $self, $block ) = @_;

    foreach my $code ( reverse @{$block->{bytecode}} ) {
        push @bytecode, @$code;
    }
}

my %regex_assertions =
  ( START_SPECIAL => 'rx_start_special',
    END_SPECIAL   => 'rx_end_special',
    );

sub _regex_assertion {
    my( $self, $tree ) = @_;
    my $type = $tree->type;

    die "Unsupported assertion '$type'" unless $regex_assertions{$type};

    push @bytecode, o( $regex_assertions{$type} );
}

sub _regex_quantifier {
    my( $self, $tree ) = @_;

    my( $start, $quant ) = ( _new_label, _new_label );
    push @bytecode, o( 'rx_start_group' );
    _to_label( $quant, $bytecode[-1] );
    _set_label( $start, scalar @bytecode );

    my $is_group = $tree->node->isa( 'Language::P::ParseTree::RXGroup' );
    my $capture = $is_group ? $tree->node->capture : 0;
    my $start_group = $group_count;
    ++$group_count if $capture;

    if( $capture ) {
        foreach my $c ( @{$tree->node->components} ) {
            $self->dispatch_regex( $c );
        }
    } else {
        $self->dispatch_regex( $tree->node );
    }

    _set_label( $quant, scalar @bytecode );
    push @bytecode, o( 'rx_quantifier', min => $tree->min, max => $tree->max,
                                        greedy => $tree->greedy,
                                        group => ( $capture ? $start_group : undef ),
                                        subgroups_start => $start_group,
                                        subgroups_end => $group_count );
    _to_label( $start, $bytecode[-1] );
}

sub _regex_group {
    my( $self, $tree ) = @_;

    if( $tree->capture ) {
        push @bytecode, o( 'rx_capture_start', group => $group_count );
    }

    foreach my $c ( @{$tree->components} ) {
        $self->dispatch_regex( $c );
    }

    if( $tree->capture ) {
        push @bytecode, o( 'rx_capture_end', group => $group_count );
        ++$group_count;
    }
}

sub _regex_exact {
    my( $self, $tree ) = @_;

    push @bytecode, o( 'rx_exact', string => $tree->value,
                                   length => length( $tree->value ) );
}

sub _regex_alternate {
    my( $self, $tree, $end ) = @_;
    my $is_last = !$tree->right->[0]
                        ->isa( 'Language::P::ParseTree::RXAlternation' );
    my( $next_l, $next_r ) = ( _new_label, _new_label );
    $end ||= _new_label;

    push @bytecode, o( 'rx_try' );
    _to_label( $next_l, $bytecode[-1] );

    foreach my $c ( @{$tree->left} ) {
        $self->dispatch_regex( $c );
    }

    push @bytecode, o( 'jump' );
    _to_label( $end, $bytecode[-1] );
    _set_label( $next_l, scalar @bytecode );

    if( !$is_last ) {
        _regex_alternate( $self, $tree->right->[0], $end );
    } else {
        foreach my $c ( @{$tree->right} ) {
            $self->dispatch_regex( $c );
        }

        _set_label( $end, scalar @bytecode );
    }
}

1;
