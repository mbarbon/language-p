package Language::P::ParseTree::PropagateContext;

use strict;
use warnings;
use base qw(Language::P::ParseTree::Visitor);

use Language::P::ParseTree qw(:all);

my %dispatch =
  ( 'Language::P::ParseTree::FunctionCall'           => '_function_call',
    'Language::P::ParseTree::Print'                  => '_print',
    'Language::P::ParseTree::Builtin'                => '_function_call',
    'Language::P::ParseTree::Overridable'            => '_function_call',
    'Language::P::ParseTree::UnOp'                   => '_unary_op',
    'Language::P::ParseTree::Parentheses'            => '_parentheses',
    'Language::P::ParseTree::Dereference'            => '_dereference',
    'Language::P::ParseTree::BinOp'                  => '_binary_op',
    'Language::P::ParseTree::Symbol'                 => '_symbol',
    'Language::P::ParseTree::Constant'               => '_noop',
    'Language::P::ParseTree::LexicalDeclaration'     => '_symbol',
    'Language::P::ParseTree::LexicalSymbol'          => '_symbol',
    'Language::P::ParseTree::List'                   => '_list',
    'Language::P::ParseTree::Conditional'            => '_cond',
    'Language::P::ParseTree::ConditionalLoop'        => '_cond_loop',
    'Language::P::ParseTree::Ternary'                => '_ternary',
    'Language::P::ParseTree::Block'                  => '_block',
    'Language::P::ParseTree::Subroutine'             => '_subroutine',
    'Language::P::ParseTree::SubroutineDeclaration'  => '_noop',
    'Language::P::ParseTree::QuotedString'           => '_quoted_string',
    'Language::P::ParseTree::Subscript'              => '_subscript',
    'Language::P::ParseTree::Slice'                  => '_slice',
    'Language::P::ParseTree::Pattern'                => '_noop',
    'Language::P::ParseTree::InterpolatedPattern'    => '_pattern',
    'Language::P::ParseTree::Substitution'           => '_substitution',
    'Language::P::ParseTree::Foreach'                => '_foreach',
    'Language::P::ParseTree::For'                    => '_for',
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

    Carp::confess( "Unhandled context for ", ref( $tree ), "\n" );
}

sub _symbol {
    my( $self, $tree, $cxt ) = @_;

    if( $tree->sigil eq '@' || $tree->sigil eq '%' ) {
        $tree->{context} = $cxt;
    } else {
        $tree->{context} = $cxt & CXT_LIST ? _lv( CXT_SCALAR, $cxt ) : $cxt;
    }
}

sub _quoted_string {
    my( $self, $tree, $cxt ) = @_;

    foreach my $component ( @{$tree->components} ) {
        $self->visit( $component, CXT_SCALAR );
    }
}

sub _subscript {
    my( $self, $tree, $cxt ) = @_;

    $tree->{context} = $cxt;

    $self->visit( $tree->subscripted, $tree->reference ? CXT_SCALAR|CXT_VIVIFY :
                                                         CXT_LIST );
    $self->visit( $tree->subscript, CXT_SCALAR );
}

sub _slice {
    my( $self, $tree, $cxt ) = @_;

    $tree->{context} = $cxt;

    $self->visit( $tree->subscripted, $tree->reference ? CXT_SCALAR|CXT_VIVIFY :
                                                         CXT_LIST );
    $self->visit( $tree->subscript, CXT_LIST );
}

sub _list {
    my( $self, $tree, $cxt ) = @_;

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

sub _function_call {
    my( $self, $tree, $cxt ) = @_;

    $tree->{context} = $cxt;
    my $arg_cxt = $tree->function eq 'return' ? CXT_CALLER : CXT_LIST;
    $self->visit( $tree->function, CXT_SCALAR ) if ref $tree->function;

    # FIXME prototypes
    if( $tree->arguments ) {
        foreach my $arg ( @{$tree->arguments} ) {
            $self->visit( $arg, $arg_cxt );
        }
    }
}

sub _print {
    my( $self, $tree, $cxt ) = @_;

    $self->_function_call( $tree, $cxt );
    $self->visit( $tree->filehandle, CXT_SCALAR ) if $tree->filehandle;
}

sub _unary_op {
    my( $self, $tree, $cxt ) = @_;

    $tree->{context} = $cxt;
    $self->visit( $tree->left, CXT_SCALAR );
}

sub _parentheses {
    my( $self, $tree, $cxt ) = @_;

    $tree->{context} = $cxt;
    $self->visit( $tree->left, $cxt );
}

sub _dereference {
    my( $self, $tree, $cxt ) = @_;

    $tree->{context} = $cxt | ( $cxt & CXT_LVALUE ? CXT_VIVIFY : 0 );
    $self->visit( $tree->left, CXT_SCALAR );
}

sub _binary_op {
    my( $self, $tree, $cxt ) = @_;

    $tree->{context} = $cxt;

    # FIXME some binary operators do not force scalar context

    if(    $tree->op eq '||' || $tree->op eq '&&' || $tree->op eq 'and'
        || $tree->op eq 'or' ) {
        $self->visit( $tree->left, CXT_SCALAR );
        $self->visit( $tree->right, _lv( $cxt & CXT_VOID ? CXT_VOID :
                                         $cxt & CXT_CALLER ? CXT_CALLER :
                                                             CXT_SCALAR,
                                         $cxt ) );
    } elsif( $tree->op eq '=' ) {
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
}

sub _for {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->condition, CXT_SCALAR );
    $self->visit( $tree->initializer, CXT_VOID );
    $self->visit( $tree->step, CXT_VOID );
    $self->visit( $tree->block, CXT_VOID );
}

sub _cond_loop {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->condition, CXT_SCALAR );
    $self->visit( $tree->block, CXT_VOID );
}

sub _cond {
    my( $self, $tree, $cxt ) = @_;

    $self->visit( $tree->iffalse->block, $cxt ) if $tree->iffalse;
    foreach my $iftrue ( @{$tree->iftrues} ) {
        $self->visit( $iftrue->condition, CXT_SCALAR );
        $self->visit( $iftrue->block, $cxt );
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

    $tree->{context} = $cxt;

    $self->visit( $tree->condition, CXT_SCALAR );
    $self->visit( $tree->iftrue, $cxt );
    $self->visit( $tree->iffalse, $cxt );
}

1;
