package Language::P::Generator;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

__PACKAGE__->mk_ro_accessors( qw(runtime) );

use Language::P::Opcodes qw(o);
use Language::P::Value::StringNumber;
use Language::P::Value::Handle;
use Language::P::Value::ScratchPad;
use Language::P::Value::Regex;
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
    my( $self, $code ) = @_;

    pop @code_stack;

    # TODO do not use global
    *bytecode = @code_stack ? $code_stack[-1][0]->bytecode : [];
}

sub process {
    my( $self, $tree ) = @_;

    push @{$code_stack[-1][1]}, $tree;

    return;
}

sub process_pending {
    my( $self ) = @_;

    foreach my $tree ( @{$code_stack[-1][1]} ) {
        if( $debug_options{parse_tree} ) {
            print STDERR $tree->pretty_print;
        }

        $self->dispatch( $tree );
    }
    $code_stack[-1][1] = []
}

sub process_regex {
    my( $self, $regex ) = @_;
    my $rx = Language::P::Value::Regex->new
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

    my $sub = Language::P::Value::Subroutine::Stub->new
                  ( { name     => $name,
                      } );
    $self->runtime->symbol_table->set_symbol( $name, '&', $sub );
}

sub finished {
    my( $self ) = @_;

    $self->process_pending;
    $self->_allocate_lexicals;

    if( $code_stack[-1][0]->isa( 'Language::P::Value::Subroutine' ) ) {
        push @bytecode, o( 'return' );
    } else {
        push @bytecode, o( 'end' );
    }
}

my %dispatch =
  ( 'Language::P::ParseTree::FunctionCall'           => '_function_call',
    'Language::P::ParseTree::Builtin'                => '_builtin',
    'Language::P::ParseTree::Overridable'            => '_builtin',
    'Language::P::ParseTree::Print'                  => '_print',
    'Language::P::ParseTree::UnOp'                   => '_unary_op',
    'Language::P::ParseTree::BinOp'                  => '_binary_op',
    'Language::P::ParseTree::Constant'               => '_constant',
    'Language::P::ParseTree::Number'                 => '_constant',
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

my %reverse_conditionals =
  ( '<'      => '>=',
    '>'      => '<=',
    '<='     => '>',
    '>='     => '<',
    '=='     => '!=',
    '!='     => '==',
    );

my %conditionals =
  ( '<'      => 'compare_i_lt_int',
    'lt'     => 'compare_s_lt_int',
    '>'      => 'compare_i_gt_int',
    'gt'     => 'compare_s_gt_int',
    '<='     => 'compare_i_le_int',
    'le'     => 'compare_s_le_int',
    '>='     => 'compare_i_ge_int',
    'ge'     => 'compare_s_ge_int',
    '=='     => 'compare_i_eq_int',
    'eq'     => 'compare_s_eq_int',
    '!='     => 'compare_i_ne_int',
    'ne'     => 'compare_s_ne_int',
    );

my %short_circuit =
  ( '&&'     => 'jump_if_false',
    '||'     => 'jump_if_true',
    'and'    => 'jump_if_false',
    'or'     => 'jump_if_true',
    );

my %unary =
  ( '-'      => 'negate',
    '!'      => 'not',
    '\\'     => 'reference',
    '$'      => 'dereference_scalar',
    backtick => 'backtick',
    );

my %builtins =
  ( print    => 'print',
    return   => 'return',
    unlink   => 'unlink',
    %short_circuit,
    '.'      => 'concat',
    '+'      => 'add',
    '*'      => 'multiply',
    '-'      => 'subtract',
    '=~'     => 'rx_match',
    '='      => 'assign',
    '<='     => 'compare_i_le_scalar',
    'le'     => 'compare_s_le_scalar',
    '=='     => 'compare_i_eq_scalar',
    'eq'     => 'compare_s_eq_scalar',
    '!='     => 'compare_i_ne_scalar',
    'ne'     => 'compare_s_ne_scalar',
    );

my %builtins_no_list =
  ( abs      => 'abs',
    defined  => 'defined',
    undef    => 'undef',
    );

sub _print {
    my( $self, $tree ) = @_;

    push @bytecode, o( 'start_call' );

    if( $tree->filehandle ) {
        $self->dispatch( $tree->filehandle );
        # FIXME HACK
        push @bytecode, o( 'push_scalar' );
    } else {
        my $out = Language::P::Value::Handle->new( { handle => \*STDOUT } );
        push @bytecode, o( 'constant', value => $out ),
                        o( 'push_scalar' );
    }

    foreach my $arg ( @{$tree->arguments} ) {
        $self->dispatch( $arg );
        # FIXME HACK
        push @bytecode, o( 'push_scalar' );
    }

    push @bytecode, o( $builtins{$tree->function} );
}

sub _builtin {
    my( $self, $tree ) = @_;

    if( $tree->function eq 'undef' && !$tree->arguments ) {
        push @bytecode, o( 'constant',
                           value => Language::P::Value::StringNumber->new );
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

    push @bytecode, o( 'start_call' );

    foreach my $arg ( @{$tree->arguments || []} ) {
        $self->dispatch( $arg );
        # FIXME HACK
        push @bytecode, o( 'push_scalar' );
    }

    Carp::confess( "Unknown '" . $tree->function . "'" )
        unless ref( $tree->function ) || $builtins{$tree->function};

    if( ref( $tree->function ) ) {
        $self->dispatch( $tree->function );
        push @bytecode, o( 'call' );
    } else {
        push @bytecode, o( $builtins{$tree->function} );
    }
}

sub _list {
    my( $self, $tree ) = @_;

    push @bytecode, o( 'start_list' );

    foreach my $arg ( @{$tree->expressions} ) {
        $self->dispatch( $arg );
        # HACK
        push @bytecode, o( 'push_scalar' );
    }
}

sub _unary_op {
    my( $self, $tree ) = @_;

    die $tree->op unless $unary{$tree->op};

    $self->dispatch( $tree->left );

    push @bytecode, o( $unary{$tree->op} );
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
             o( $short_circuit{$tree->op} );
        _to_label( $end, $bytecode[-1] );

        # evalutates right only if this is the correct return value
        $self->dispatch( $tree->right );

        _set_label( $end, scalar @bytecode );
    } else {
        $self->dispatch( $tree->right, $tree->op eq '=~' ? 1 : 0 );
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
    my $type = $tree->type;
    my $v;

    if( $type eq 'number' ) {
        if( $tree->flags == NUM_INTEGER ) {
            $v = Language::P::Value::StringNumber
                     ->new( { integer => $tree->value } );
        } elsif( $tree->flags == NUM_FLOAT ) {
            $v = Language::P::Value::StringNumber
                     ->new( { float => $tree->value } );
        } elsif( $tree->flags & NUM_OCTAL ) {
            $v = Language::P::Value::StringNumber
                     ->new( { integer => oct '0' . $tree->value } );
        } elsif( $tree->flags & NUM_HEXADECIMAL ) {
            $v = Language::P::Value::StringNumber
                     ->new( { integer => oct '0x' . $tree->value } );
        } elsif( $tree->flags & NUM_BINARY ) {
            $v = Language::P::Value::StringNumber
                     ->new( { integer => oct '0b' . $tree->value } );
        }
    } elsif( $type eq 'string' ) {
        $v = Language::P::Value::StringNumber->new( { string => $tree->value } );
    } else {
        die $type;
    }

    push @bytecode, o( 'constant', value => $v );
}

my %sigils =
  ( '$'  => 'scalar',
    '&'  => 'subroutine',
    '@'  => 'array',
    '$#' => 'array',
    );

sub _symbol {
    my( $self, $tree ) = @_;

    if( $tree->sigil eq '*' ) {
        push @bytecode, o( 'glob', name => $tree->name, create => 1 );
        return;
    }

    my $slot = $sigils{$tree->sigil};
    die $tree->sigil unless $slot;

    push @bytecode,
         o( 'glob',             name => $tree->name, create => 1 ),
         o( 'glob_slot_create', slot => $slot );

    if( $tree->sigil eq '$#' ) {
        push @bytecode, o( 'array_size' );
    }
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
        my $is_unless = $elsif->[0] eq 'unless';
        my( $true, $false ) = ( _new_label, _new_label );
        $self->dispatch_cond( $elsif->[1], $is_unless ? ( $false, $true ) :
                                                        ( $true, $false ) );
        _set_label( $true, scalar @bytecode );
        $self->dispatch( $elsif->[2] );
        push @bytecode, o( 'jump' );
        _to_label( $end, $bytecode[-1] );
        _set_label( $false, scalar @bytecode );
    }
    if( $tree->iffalse ) {
        $self->dispatch( $tree->iffalse->[2] );
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

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
    }
}

sub _subroutine_decl {
    my( $self, $tree ) = @_;

    # nothing to do
}

sub _subroutine {
    my( $self, $tree ) = @_;

    my $sub = Language::P::Value::Subroutine->new
                  ( { bytecode => [],
                      name     => $tree->name,
                      } );
    $self->push_code( $sub );

    foreach my $line ( @{$tree->lines} ) {
        $self->dispatch( $line );
    }

    $self->finished;
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

    if( $tree->type eq '[' ) {
        push @bytecode, o( 'array_element' );
    } elsif( $tree->type eq '{' ) {
        push @bytecode, o( 'hash_element' );
    } else {
        die $tree->type;
    }
}

sub _pattern {
    my( $self, $tree, $explicit_bind ) = @_;

    die "Pattern not bound by match operator" unless $explicit_bind;

    my $re = $self->process_regex( $tree );
    push @bytecode, o( 'constant', value => $re );
}

sub _allocate_lexicals {
    my( $self ) = @_;

    my $pad = Language::P::Value::ScratchPad->new;
    my $has_pad;
    foreach my $op ( @bytecode ) {
        next if !$op->{lexical};

#         use Data::Dumper;
#         print Dumper $op;

        # FIXME make the lexical slot an object with accessors
        if( $op->{level} == 0 && $op->{lexical}->{index} == -100 ) {
            if( $op->{lexical}->{in_pad} ) {
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
