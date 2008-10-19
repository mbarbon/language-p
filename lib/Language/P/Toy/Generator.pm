package Language::P::Toy::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_ro_accessors( qw(runtime) );

use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::StringNumber;
use Language::P::Toy::Value::Handle;
use Language::P::Toy::Value::ScratchPad;
use Language::P::Toy::Value::Code;
use Language::P::Toy::Value::Regex;
use Language::P::ParseTree qw(:all);

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

    push @code_stack, [ $code, [] ];

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
        locals   => [],
        lexicals => [],
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
    'Language::P::ParseTree::LexicalSymbol'          => '_lexical_declaration',
    'Language::P::ParseTree::List'                   => '_list',
    'Language::P::ParseTree::Conditional'            => '_cond',
    'Language::P::ParseTree::ConditionalLoop'        => '_cond_loop',
    'Language::P::ParseTree::Ternary'                => '_ternary',
    'Language::P::ParseTree::Block'                  => '_block',
    'Language::P::ParseTree::Subroutine'             => '_subroutine',
    'Language::P::ParseTree::SubroutineDeclaration'  => '_subroutine_decl',
    'Language::P::ParseTree::QuotedString'           => '_quoted_string',
    'Language::P::ParseTree::Subscript'              => '_subscript',
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
        push @bytecode, o( 'constant',
                           value => Language::P::Toy::Value::StringNumber->new );
    } elsif( $builtins_no_list{$tree->function} ) {
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

    push @bytecode, o( 'start_list' );

    foreach my $arg ( @{$tree->arguments || []} ) {
        $self->dispatch( $arg );
    }

    push @bytecode, o( 'end_list' );

    Carp::confess( "Unknown '" . $tree->function . "'" )
        unless ref( $tree->function ) || $builtins{$tree->function};

    if( ref( $tree->function ) ) {
        $self->dispatch( $tree->function );
        push @bytecode, o( 'call', context => $tree->context & CXT_CALL_MASK );
    } else {
        if( $tree->function eq 'return' ) {
            my $block = $current_block;
            while( $block ) {
                _restore_locals( $self, $block );
                last if $block->{is_sub};
                $block = $block->{outer};
            }
        }
        push @bytecode, o( $builtins{$tree->function} );
    }
}

sub _list {
    my( $self, $tree ) = @_;

    push @bytecode, o( 'start_list' );

    foreach my $arg ( @{$tree->expressions} ) {
        $self->dispatch( $arg );
    }

    push @bytecode, o( 'end_list' );
}

sub _unary_op {
    my( $self, $tree ) = @_;

    die $tree->op unless $unary{$tree->op};

    $self->dispatch( $tree->left );

    push @bytecode, o( $unary{$tree->op} );
}

sub _local {
    my( $self, $tree ) = @_;

    # FIXME only works for plain scalars
    my $index = $code_stack[-1][0]->stack_size;
    ++$code_stack[-1][0]->{stack_size};

    push @bytecode,
         o( 'glob',          name => $tree->left->name, create => 1 ),
         o( 'dup' ), o( 'dup' ),
         o( 'glob_slot',     slot => 'scalar' ),
         o( 'lexical_set',   index => $index ),
         o( 'constant',      value => Language::P::Toy::Value::StringNumber->new ),
         o( 'glob_slot_set', slot => 'scalar' ),
         o( 'glob_slot',     slot => 'scalar' );

    push @{$current_block->{locals}},
         { name  => $tree->left->name,
           index => $index };
}

sub _parentheses {
    my( $self, $tree ) = @_;

    $self->dispatch( $tree->left );
}

sub _binary_op {
    my( $self, $tree ) = @_;

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

my %sigils =
  ( VALUE_SCALAR() => 'scalar',
    VALUE_SUB()    => 'subroutine',
    VALUE_ARRAY()  => 'array',
    );

sub _symbol {
    my( $self, $tree ) = @_;

    if( $tree->sigil == VALUE_GLOB ) {
        push @bytecode, o( 'glob', name => $tree->name, create => 1 );
        return;
    }

    my $slot = $sigils{$tree->sigil};
    die $tree->sigil unless $slot;

    push @bytecode,
         o( 'glob',             name => $tree->name, create => 1 ),
         o( 'glob_slot_create', slot => $slot );
}

sub _lexical_declaration {
    my( $self, $tree ) = @_;

    die unless defined $tree->{slot}->{level};
#     use Data::Dumper;
#     print Dumper $tree;
    my $in_pad = $tree->{slot}->{slot}->{in_pad};
    push @bytecode,
        o( $in_pad ? 'lexical_pad' : 'lexical',
           lexical  => $tree->{slot}->{slot},
           level    => $tree->{slot}->{level},
           );
}

sub _cond_loop {
    my( $self, $tree ) = @_;

    die $tree->block_type unless $tree->block_type eq 'while';

    my( $start, $true, $false ) = ( _new_label, _new_label, _new_label );
    _set_label( $start, scalar @bytecode );

    $self->dispatch_cond( $tree->condition, $true, $false );
    _set_label( $true, scalar @bytecode );
    $self->dispatch( $tree->block );
    push @bytecode, o( 'jump' );
    _to_label( $start, $bytecode[-1] );
    _set_label( $false, scalar @bytecode );
}

sub _cond {
    my( $self, $tree ) = @_;

    my $end = _new_label;
    foreach my $elsif ( @{$tree->iftrues} ) {
        my $is_unless = $elsif->block_type eq 'unless';
        my( $true, $false ) = ( _new_label, _new_label );
        $self->dispatch_cond( $elsif->condition,
                              $is_unless ? ( $false, $true ) :
                                           ( $true, $false ) );
        _set_label( $true, scalar @bytecode );
        $self->dispatch( $elsif->block );
        push @bytecode, o( 'jump' );
        _to_label( $end, $bytecode[-1] );
        _set_label( $false, scalar @bytecode );
    }
    if( $tree->iffalse ) {
        $self->dispatch( $tree->iffalse->block );
    }
    _set_label( $end, scalar @bytecode );
}

sub _ternary {
    my( $self, $tree ) = @_;

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

    $self->push_block;

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
    }

    _restore_locals( $self, $current_block );
    $self->pop_block;
}

sub _subroutine_decl {
    my( $self, $tree ) = @_;

    # nothing to do
}

sub _subroutine {
    my( $self, $tree ) = @_;

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

    $self->runtime->symbol_table->set_symbol( $tree->name, '&', $sub );
}

sub _quoted_string {
    my( $self, $tree ) = @_;

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

sub _pattern {
    my( $self, $tree ) = @_;

    my $re = $self->process_regex( $tree );
    push @bytecode, o( 'constant', value => $re );
}

sub _allocate_lexicals {
    my( $self, $is_sub ) = @_;

    my $pad = Language::P::Toy::Value::ScratchPad->new;
    my $sub_args = $is_sub ? $pad->add_value : -1;
    my $has_pad;
    foreach my $op ( @bytecode ) {
        next if !$op->{lexical};

#         use Data::Dumper;
#         print Dumper $op;

        # FIXME make the lexical slot an object with accessors
        if( $op->{level} == 0 && !defined $op->{lexical}->{index} ) {
            if(    $op->{lexical}->{name} eq '_'
                && $op->{lexical}->{sigil} == VALUE_ARRAY ) {
                $op->{lexical}->{index} = $sub_args;
            } elsif( $op->{lexical}->{in_pad} ) {
                if( !$has_pad ) {
                    $code_stack[-1][0]->{lexicals} = $pad;
                    $pad->{outer} = $code_stack[-1][0]->{outer};
                    $has_pad = 1;
                }
                $op->{lexical}->{index} = $pad->add_value;
            } else {
                $op->{lexical}->{index} = $code_stack[-1][0]->stack_size;
                ++$code_stack[-1][0]->{stack_size};
            }
        }

        $op->{in_pad} = $op->{lexical}->{in_pad};
        $op->{index} = $op->{lexical}->{index};
        delete $op->{lexical};
    }
}

sub _restore_locals {
    my( $self, $block ) = @_;

    foreach my $local ( reverse @{$block->{locals}} ) {
        push @bytecode,
             o( 'glob',          name => $local->{name} ),
             o( 'lexical',       index => $local->{index} ),
             o( 'glob_slot_set', slot => 'scalar' ),
             o( 'lexical_clear', index => $local->{index} );
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
