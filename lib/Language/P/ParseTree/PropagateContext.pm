package Language::P::ParseTree::PropagateContext;

use strict;
use warnings;
use parent qw(Language::P::ParseTree::Visitor);

use Language::P::Constants qw(:all);
use Language::P::Opcodes qw(:all);
use Language::P::ParseTree;

my %dispatch =
  ( 'Language::P::ParseTree::FunctionCall'           => '_function_call',
    'Language::P::ParseTree::BuiltinIndirect'        => '_builtin_indirect',
    'Language::P::ParseTree::Builtin'                => '_function_call',
    'Language::P::ParseTree::Overridable'            => '_function_call',
    'Language::P::ParseTree::MethodCall'             => '_method_call',
    'Language::P::ParseTree::UnOp'                   => '_unary_op',
    'Language::P::ParseTree::Parentheses'            => '_parentheses',
    'Language::P::ParseTree::Dereference'            => '_dereference',
    'Language::P::ParseTree::Local'                  => '_local',
    'Language::P::ParseTree::Jump'                   => '_jump',
    'Language::P::ParseTree::BinOp'                  => '_binary_op',
    'Language::P::ParseTree::Symbol'                 => '_symbol',
    'Language::P::ParseTree::Constant'               => '_set_context_nolvalue',
    'Language::P::ParseTree::LexicalDeclaration'     => '_symbol',
    'Language::P::ParseTree::LexicalSymbol'          => '_symbol',
    'Language::P::ParseTree::List'                   => '_list',
    'Language::P::ParseTree::Conditional'            => '_cond',
    'Language::P::ParseTree::ConditionalLoop'        => '_cond_loop',
    'Language::P::ParseTree::Ternary'                => '_ternary',
    'Language::P::ParseTree::Block'                  => '_block',
    'Language::P::ParseTree::EvalBlock'              => '_expression_block',
    'Language::P::ParseTree::DoBlock'                => '_expression_block',
    'Language::P::ParseTree::BareBlock'              => '_bare_block',
    'Language::P::ParseTree::Subroutine'             => '_subroutine',
    'Language::P::ParseTree::AnonymousSubroutine'    => '_subroutine',
    'Language::P::ParseTree::SubroutineDeclaration'  => '_noop',
    'Language::P::ParseTree::QuotedString'           => '_quoted_string',
    'Language::P::ParseTree::Subscript'              => '_subscript',
    'Language::P::ParseTree::Slice'                  => '_slice',
    'Language::P::ParseTree::ReferenceConstructor'   => '_ref_constr',
    'Language::P::ParseTree::Pattern'                => '_noop',
    'Language::P::ParseTree::InterpolatedPattern'    => '_pattern',
    'Language::P::ParseTree::Substitution'           => '_substitution',
    'Language::P::ParseTree::Transliteration'        => '_noop',
    'Language::P::ParseTree::Foreach'                => '_foreach',
    'Language::P::ParseTree::For'                    => '_for',
    'Language::P::ParseTree::LexicalState'           => '_noop',
    'Language::P::ParseTree::Empty'                  => '_noop',
    'Language::P::ParseTree::Use'                    => '_use',
    'DEFAULT'                                        => '_noisy_noop',
    );

sub method_map { \%dispatch }

sub _lv { return $_[0] | ( $_[1] & CXT_LVALUE ) }

sub _noop {
    my( $self, $tree, $cxt ) = @_;

    # nothing to do
}

sub _noisy_noop {
    my( $self, $tree, $cxt ) = @_;

    require Carp;

    Carp::confess( "Unhandled context for ", ref( $tree ) || $tree, "\n" );
}

sub _set_context {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );
}

sub _set_context_nolvalue {
    my( $self, $tree, $cxt ) = @_;

    if( $cxt & CXT_LVALUE ) {
        throw Language::P::Parser::Exception
            ( message  => "Can't modify constant",
              position => $tree->pos,
              );
    }

    $tree->set_attribute( 'context', $cxt );
}

sub _symbol {
    my( $self, $tree, $cxt ) = @_;

    if( $tree->sigil == VALUE_ARRAY || $tree->sigil == VALUE_HASH ) {
        $tree->set_attribute( 'context', $cxt );
    } elsif( $tree->sigil == VALUE_STASH ) {
        $tree->set_attribute( 'context', $cxt );
    } else {
        $tree->set_attribute( 'context', $cxt & CXT_LIST ? _lv( CXT_SCALAR, $cxt ) : $cxt );
    }
}

sub _quoted_string {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );
    foreach my $component ( @{$tree->components} ) {
        $self->visit( $component, CXT_SCALAR );
    }
}

sub _subscript {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );

    my $sub_cxt = $tree->reference && $tree->type != VALUE_GLOB ?
                      CXT_SCALAR|CXT_VIVIFY :
                      CXT_LIST;
    $self->visit( $tree->subscripted, $sub_cxt );
    $self->visit( $tree->subscript, CXT_SCALAR );
}

sub _slice {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );

    $self->visit( $tree->subscripted, $tree->reference ? CXT_SCALAR|CXT_VIVIFY :
                                                         CXT_LIST );
    $self->visit( $tree->subscript, CXT_LIST );
}

sub _list {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );
    my $inner = _lv( $cxt & CXT_LIST   ? CXT_LIST :
                     $cxt & CXT_CALLER ? CXT_CALLER :
                                         CXT_VOID, $cxt );
    if( @{$tree->expressions} ) {
        $self->visit( $tree->expressions->[-1], $cxt );
        for( my $i = $#{$tree->expressions} - 1; $i >= 0; --$i ) {
            $self->visit( $tree->expressions->[$i], $inner );
        }
    }
}

sub _block {
    my( $self, $tree, $cxt ) = @_;

    if( @{$tree->lines} ) {
        $self->visit( $tree->lines->[-1], $cxt );
        for( my $i = $#{$tree->lines} - 1; $i >= 0; --$i ) {
            $self->visit( $tree->lines->[$i], CXT_VOID );
        }
    }
}

sub _bare_block {
    my( $self, $tree, $cxt ) = @_;

    _block( $self, $tree, $cxt );
    $self->visit( $tree->continue, CXT_VOID ) if $tree->continue;
}

sub _expression_block {
    my( $self, $tree, $cxt ) = @_;

    _block( $self, $tree, $cxt );
    $tree->set_attribute( 'context', $cxt );
}

sub _function_call {
    my( $self, $tree, $cxt ) = @_;
    my $arg_cxts = $tree->runtime_context || [ CXT_LIST ];

    if( $cxt & CXT_LVALUE && !ref $tree->function ) {
        if( $tree->function == OP_SUBSTR ) {
            if( @{$tree->arguments} == 4 ) {
                throw Language::P::Parser::Exception
                    ( message  => "Can't modify substr",
                      position => $tree->pos,
                      );
            } else {
                $arg_cxts = [ CXT_SCALAR|CXT_LVALUE, CXT_SCALAR,
                              CXT_SCALAR, CXT_SCALAR ];
            }
        } elsif( $tree->function == OP_VEC ) {
            $arg_cxts = [ CXT_SCALAR|CXT_LVALUE, CXT_SCALAR, CXT_SCALAR ];
        } elsif( $tree->function == OP_POS ) {
            $arg_cxts = [ CXT_SCALAR|CXT_LVALUE ];
        } elsif( $tree->function != OP_UNDEF ) {
            my $op_name = $NUMBER_TO_NAME{$tree->function};

            throw Language::P::Parser::Exception
                ( message  => "Can't modify $op_name",
                  position => $tree->pos,
                  );
        }
    } elsif( !ref $tree->function ) {
        if( $tree->function == OP_SUBSTR && @{$tree->arguments} == 4 ) {
            $arg_cxts = [ CXT_SCALAR|CXT_LVALUE, CXT_SCALAR,
                          CXT_SCALAR, CXT_SCALAR ];
        }
    }

    if( !ref $tree->function && $tree->function == OP_RETURN ) {
        $tree->set_attribute( 'context', CXT_CALLER );
    } else {
        $tree->set_attribute( 'context', $cxt );
    }
    $self->visit( $tree->function, CXT_SCALAR ) if ref $tree->function;

    if( $tree->arguments ) {
        my $arg_index = 0;
        foreach my $arg ( @{$tree->arguments} ) {
            my $arg_cxt = $arg_index <= $#$arg_cxts ? $arg_cxts->[$arg_index] :
                                                      $arg_cxts->[-1];
            $self->visit( $arg, $arg_cxt );
            ++$arg_index;
        }
    }
}

sub _method_call {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );
    $self->visit( $tree->invocant, CXT_SCALAR );
    $self->visit( $tree->method, CXT_SCALAR ) if ref $tree->method;

    if( $tree->arguments ) {
        foreach my $arg ( @{$tree->arguments} ) {
            $self->visit( $arg, CXT_LIST );
        }
    }
}

sub _builtin_indirect {
    my( $self, $tree, $cxt ) = @_;

    $self->_function_call( $tree, $cxt );
    if( $tree->indirect ) {
        my $arg_cxt = $tree->function == OP_MAP ? CXT_LIST : CXT_SCALAR;
        $self->visit( $tree->indirect, $arg_cxt );
    }
}

sub _unary_op {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );
    if(    $tree->op == OP_PREINC
        || $tree->op == OP_PREDEC
        || $tree->op == OP_POSTINC
        || $tree->op == OP_POSTDEC ) {
        $self->visit( $tree->left, CXT_SCALAR|CXT_LVALUE );
    } else {
        $self->visit( $tree->left, CXT_SCALAR );
    }
}

sub _parentheses {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );
    $self->visit( $tree->left, $cxt );
}

sub _dereference {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt | ( $cxt & CXT_LVALUE ? CXT_VIVIFY : 0 ) );
    $self->visit( $tree->left, CXT_SCALAR );
}

sub _local {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );
    $self->visit( $tree->left, $cxt|CXT_LVALUE );
}

sub _jump {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->left, CXT_SCALAR ) if ref $tree->left;
}

sub _binary_op {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );

    # FIXME some binary operators do not force scalar context

    # FIXME no idea how this ties in with OP_DEFINED_OR --Steffen
    if(    $tree->op == OP_LOG_OR || $tree->op == OP_LOG_AND
        || $tree->op == OP_DEFINED_OR ) {
        $self->visit( $tree->left, CXT_SCALAR );
        $self->visit( $tree->right, _lv( $cxt & CXT_VOID ? CXT_VOID :
                                         $cxt & CXT_CALLER ? CXT_CALLER :
                                                             CXT_SCALAR,
                                         $cxt ) );
    } elsif(    $tree->op == OP_ASSIGN
             || $tree->op == OP_ADD_ASSIGN
             || $tree->op == OP_BIT_AND_ASSIGN
             || $tree->op == OP_BIT_OR_ASSIGN
             || $tree->op == OP_BIT_XOR_ASSIGN
             || $tree->op == OP_CONCATENATE_ASSIGN
             || $tree->op == OP_DIVIDE_ASSIGN
             || $tree->op == OP_LOG_AND_ASSIGN
             || $tree->op == OP_LOG_OR_ASSIGN
             || $tree->op == OP_DEFINED_OR_ASSIGN
             || $tree->op == OP_MODULUS_ASSIGN
             || $tree->op == OP_MULTIPLY_ASSIGN
             || $tree->op == OP_POWER_ASSIGN
             || $tree->op == OP_REPEAT_ASSIGN
             || $tree->op == OP_SHIFT_LEFT_ASSIGN
             || $tree->op == OP_SHIFT_RIGHT_ASSIGN
             || $tree->op == OP_SUBTRACT_ASSIGN ) {
        my $left_cxt = $tree->left->lvalue_context;

        $self->visit( $tree->left, $left_cxt|CXT_LVALUE );
        $self->visit( $tree->right, $left_cxt );
    } else {
        $self->visit( $tree->left, CXT_SCALAR );
        $self->visit( $tree->right, CXT_SCALAR );
    }
}

sub _pattern {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );
    $self->visit( $tree->string, CXT_SCALAR );
}

sub _substitution {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->pattern, CXT_SCALAR );
    $self->visit( $tree->replacement, CXT_SCALAR );
}

sub _foreach {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->variable, CXT_SCALAR );
    $self->visit( $tree->expression, CXT_LIST );
    $self->visit( $tree->block, CXT_VOID );
    $self->visit( $tree->continue, CXT_VOID ) if $tree->continue;
}

sub _for {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->condition, CXT_SCALAR ) if $tree->condition;
    $self->visit( $tree->initializer, CXT_VOID ) if $tree->initializer;
    $self->visit( $tree->step, CXT_VOID ) if $tree->step;
    $self->visit( $tree->block, CXT_VOID );
}

sub _cond_loop {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->condition, CXT_SCALAR );
    $self->visit( $tree->block, CXT_VOID );
    $self->visit( $tree->continue, CXT_VOID ) if $tree->continue;
}

sub _cond {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->iffalse->block, $cxt ) if $tree->iffalse;
    foreach my $iftrue ( @{$tree->iftrues} ) {
        $self->visit( $iftrue->condition, CXT_SCALAR );
        $self->visit( $iftrue->block, $cxt );
    }
}

sub _use {
    my( $self, $tree, $cxt ) = @_;

    return unless $tree->import;
    foreach my $arg ( @{$tree->import} ) {
        $self->visit( $arg, CXT_LIST );
    }
}

sub _subroutine {
    my( $self, $tree, $cxt ) = @_;

    if( @{$tree->lines} ) {
        $self->visit( $tree->lines->[-1], CXT_CALLER );
        for( my $i = $#{$tree->lines} - 1; $i >= 0; --$i ) {
            $self->visit( $tree->lines->[$i], CXT_VOID );
        }
    }
}

sub _ternary {
    my( $self, $tree, $cxt ) = @_;

    $tree->set_attribute( 'context', $cxt );

    $self->visit( $tree->condition, CXT_SCALAR );
    $self->visit( $tree->iftrue, $cxt );
    $self->visit( $tree->iffalse, $cxt );
}

sub _ref_constr {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->expression, CXT_LIST ) if $tree->expression;
}

1;
