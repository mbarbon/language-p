package Language::P::Parser;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Lexer qw(:all);
use Language::P::ParseTree qw(:all);
use Language::P::Parser::Regex;
use Language::P::Value::ScratchPad;
use Language::P::Value::Code;
use Language::P::ParseTree::PropagateContext;

__PACKAGE__->mk_ro_accessors( qw(lexer generator runtime) );
__PACKAGE__->mk_accessors( qw(_package _lexicals _pending_lexicals
                              _current_sub _propagate_context) );

use constant
  { PREC_HIGHEST       => 0,
    PREC_TERNARY       => 18,
    PREC_TERNARY_COLON => 40,
    PREC_LISTOP        => 21,
    PREC_LOWEST        => 50,
    };

my %prec_assoc_bin =
  ( '->'  => [ 2,  'LEFT' ],
    '**'  => [ 4,  'RIGHT' ],
    '=~'  => [ 6,  'LEFT' ],
    '!~'  => [ 6,  'LEFT' ],
    '*'   => [ 7,  'LEFT' ],
    '/'   => [ 7,  'LEFT' ],
    '%'   => [ 7,  'LEFT' ],
    'x'   => [ 7,  'LEFT' ],
    '+'   => [ 8,  'LEFT' ],
    '-'   => [ 8,  'LEFT' ],
    '.'   => [ 8,  'LEFT' ],
    '<'   => [ 11, 'NON' ],
    '>'   => [ 11, 'NON' ],
    '<='  => [ 11, 'NON' ],
    '>='  => [ 11, 'NON' ],
    'lt'  => [ 11, 'NON' ],
    'gt'  => [ 11, 'NON' ],
    'le'  => [ 11, 'NON' ],
    'ge'  => [ 11, 'NON' ],
    '=='  => [ 12, 'NON' ],
    '!='  => [ 12, 'NON' ],
    '<=>' => [ 12, 'NON' ],
    'eq'  => [ 12, 'NON' ],
    'ne'  => [ 12, 'NON' ],
    'cmp' => [ 12, 'NON' ],
    '&&'  => [ 15, 'LEFT' ],
    '||'  => [ 16, 'LEFT' ],
    '..'  => [ 17, 'NON' ],
    '...' => [ 17, 'NON' ],
    '?'   => [ 18, 'RIGHT' ], # ternary
    '='   => [ 19, 'RIGHT' ],
    '+='  => [ 19, 'RIGHT' ],
    '-='  => [ 19, 'RIGHT' ],
    '*='  => [ 19, 'RIGHT' ],
    '/='  => [ 19, 'RIGHT' ],
    # 20, comma
    # 21, list ops
    'not' => [ 22, 'RIGHT' ],
    'and' => [ 23, 'LEFT' ],
    'or'  => [ 24, 'LEFT' ],
    'xor' => [ 24, 'LEFT' ],
    ':'   => [ 40, 'RIGHT' ], # ternary, must be lowest,
    );

my %prec_assoc_un =
  ( '+'   => [ 5,  'RIGHT' ],
    '-'   => [ 5,  'RIGHT' ],
    '!'   => [ 5,  'RIGHT' ],
    '\\'  => [ 5,  'RIGHT' ],
    );

sub parse_string {
    my( $self, $string ) = @_;

    open my $fh, '<', \$string;

    $self->parse_stream( $fh );
}

sub parse_file {
    my( $self, $file ) = @_;

    open my $fh, '<', $file or die "open '$file': $!";

    $self->_package( 'main' );
    $self->parse_stream( $fh );
}

sub parse_stream {
    my( $self, $stream ) = @_;

    $self->{lexer} = Language::P::Lexer->new( { stream => $stream } );
    $self->_parse;
}

sub _parse {
    my( $self ) = @_;

    $self->_propagate_context( Language::P::ParseTree::PropagateContext->new );
    $self->_pending_lexicals( [] );
    $self->_lexicals( undef );
    $self->_enter_scope( 0 , 1 ); # FIXME eval

    my $code = Language::P::Value::Code->new( { bytecode => [],
                                                 lexicals => $self->_lexicals } );
    $self->generator->push_code( $code );
    $self->_current_sub( $code );

    while( my $line = _parse_line( $self ) ) {
        $self->_propagate_context->visit( $line, CXT_VOID );
        $self->generator->process( $line );
    }
    $self->_lexicals->keep_all_in_pad;
    $self->generator->finished;

    $self->generator->pop_code;

    return $code;
}

sub _enter_scope {
    my( $self, $is_sub, $all_in_pad ) = @_;

    $self->_lexicals( Language::P::Value::ScratchPad->new
                          ( { outer         => $self->_lexicals,
                              is_subroutine => $is_sub || 0,
                              all_in_pad    => $all_in_pad || 0,
                              } ) );
}

sub _leave_scope {
    my( $self ) = @_;

    $self->_lexicals( $self->_lexicals->outer );
}

sub _label {
    my( $self ) = @_;

    return undef;
}

sub _lex_token {
    my( $self, $type, $value ) = @_;
    my $token = $self->lexer->lex;

    return if !$value && !$type;

    if(    ( $type && $type ne $token->[0] )
        || ( $value && $value eq $token->[1] ) ) {
        Carp::confess( $token->[0], ' ', $token->[1] );
    }

    return $token;
}

sub _lex_semicolon {
    my( $self ) = @_;
    my $token = $self->lexer->lex;

    if(    ( $token->[0] eq 'SPECIAL' && $token->[1] eq 'EOF' )
        || ( $token->[0] eq 'SEMICOLON' ) ) {
        return;
    } elsif( $token->[0] eq 'CLBRK' ) {
        $self->lexer->unlex( $token );
        return;
    }

    Carp::confess( $token->[0], ' ', $token->[1] );
}

my %special_sub = map { $_ => 1 }
  ( qw(AUTOLOAD DESTROY BEGIN UNITCHECK CHECK INIT END) );

sub _parse_line {
    my( $self ) = @_;

    my $label = _label( $self );
    my $token = $self->lexer->peek( X_STATE );

    if( $token->[0] eq 'SEMICOLON' ) {
        _lex_semicolon( $self );

        return _parse_line( $self );
    } elsif( $token->[0] eq 'OPBRK' ) {
        _lex_token( $self, 'OPBRK' );

        return _parse_block_rest( $self, 1 );
    } elsif( $token->[1] eq 'sub' ) {
        return _parse_sub( $self, 1 | 2 );
    } elsif( $special_sub{$token->[1]} ) {
        return _parse_sub( $self, 1, 1 );
    } elsif( $token->[1] eq 'if' || $token->[1] eq 'unless' ) {
        return _parse_cond( $self );
    } elsif( $token->[1] eq 'while' || $token->[1] eq 'until' ) {
        return _parse_while( $self );
    } elsif( $token->[1] eq 'for' || $token->[1] eq 'foreach' ) {
        return _parse_for( $self );
    } else {
        my $sideff = _parse_sideff( $self );
        _lex_semicolon( $self );

        $self->_add_pending_lexicals;

        return $sideff;
    }

    Carp::confess $token->[0], ' ', $token->[1];
}

sub _add_pending_lexicals {
    my( $self ) = @_;

    # FIXME our() is different
    foreach my $lexical ( @{$self->_pending_lexicals} ) {
        my( undef, $slot ) = $self->_lexicals->add_name( $lexical->sigil,
                                                         $lexical->name );
        $lexical->{slot} = { slot  => $slot,
                             level => 0,
                             };
    }

    $self->_pending_lexicals( [] );
}

sub _parse_sub {
    my( $self, $flags, $no_sub_token ) = @_;
    _lex_token( $self, 'ID' ) unless $no_sub_token;
    my $name = $self->lexer->peek( X_NOTHING );

    # TODO prototypes
    if( $name->[0] eq 'ID' ) {
        die 'Syntax error: named sub' unless $flags & 1;
        _lex_token( $self, 'ID' );

        my $next = $self->lexer->lex( X_OPERATOR );

        if( $next->[0] eq 'SEMICOLON' ) {
            $self->generator->add_declaration( $name->[1] );

            return Language::P::ParseTree::SubroutineDeclaration->new
                       ( { name => $name->[1],
                           } );
        } elsif( $next->[0] ne 'OPBRK' ) {
            Carp::confess( $next->[0], ' ', $next->[1] );
        }
    } elsif( $name->[0] eq 'OPBRK' ) {
        die 'Syntax error: anonymous sub' unless $flags & 2;
        undef $name;
        _lex_token( $self, 'OPBRK' );
    } else {
        die $name->[0], ' ', $name->[1];
    }

    $self->_enter_scope( 1 );
    my $sub = Language::P::ParseTree::Subroutine->new
                  ( { lexicals => $self->_lexicals,
                      outer    => $self->_current_sub,
                      name     => $name ? $name->[1] : undef,
                      } );

    # FIXME incestuos with runtime
    my $args_slot = $self->_lexicals->add_name( '@', '_' );
    $args_slot->{index} = $self->_lexicals->add_value;

    $self->_current_sub( $sub );
    my $block = _parse_block_rest( $self, 0 );
    $sub->{lines} = $block->{lines}; # FIXME encapsulation
    $self->_leave_scope;
    $self->_current_sub( $sub->outer );

    $self->_propagate_context->visit( $sub, CXT_CALLER );

    # add a subroutine declaration, the generator might
    # not create it until later
    if( $name ) {
        $self->generator->add_declaration( $name->[1] );
    }

    return $sub;
}

sub _parse_cond {
    my( $self ) = @_;
    my $cond = _lex_token( $self, 'ID' );

    _lex_token( $self, 'OPPAR' );

    $self->_enter_scope;
    my $expr = _parse_expr( $self );
    $self->_add_pending_lexicals;

    _lex_token( $self, 'CLPAR' );
    _lex_token( $self, 'OPBRK' );

    my $block = _parse_block_rest( $self, 1 );

    my $if = Language::P::ParseTree::Conditional
                 ->new( { iftrues => [ [ $cond->[1], $expr, $block ] ],
                          } );

    for(;;) {
        my $else = $self->lexer->peek( X_STATE );
        last if    $else->[0] ne 'ID' || $else->[2] != T_KEYWORD
                || ( $else->[1] ne 'else' && $else->[1] ne 'elsif' );
        _lex_token( $self );

        my $expr;
        if( $else->[1] eq 'elsif' ) {
            _lex_token( $self, 'OPPAR' );
            $expr = _parse_expr( $self );
            _lex_token( $self, 'CLPAR' );
        }
        _lex_token( $self, 'OPBRK' );
        my $block = _parse_block_rest( $self, 1 );

        if( $expr ) {
            push @{$if->iftrues}, [ 'if', $expr, $block ];
        } else {
            $if->{iffalse} = [ 'else', undef, $block ];
        }
    }

    $self->_leave_scope;

    return $if;
}

sub _parse_for {
    my( $self ) = @_;
    my $keyword = _lex_token( $self, 'ID' );
    my $token = $self->lexer->lex( X_OPERATOR );
    my( $foreach_var, $foreach_expr );

    $self->_enter_scope;

    if( $token->[0] eq 'OPPAR' ) {
        my $expr = _parse_expr( $self );
        my $sep = $self->lexer->lex( X_OPERATOR );

        if( $sep->[0] eq 'CLPAR' ) {
            $foreach_var = _find_symbol( $self, '$', '_' );
            $foreach_expr = $expr;
        } elsif( $sep->[0] eq 'SEMICOLON' ) {
            # C-style for
            $self->_add_pending_lexicals;

            my $cond = _parse_expr( $self );
            _lex_token( $self, 'SEMICOLON' );
            $self->_add_pending_lexicals;

            my $incr = _parse_expr( $self );
            _lex_token( $self, 'CLPAR' );
            $self->_add_pending_lexicals;

            _lex_token( $self, 'OPBRK' );
            my $block = _parse_block_rest( $self, 1 );

            my $for = Language::P::ParseTree::For->new
                          ( { block_type  => 'for',
                              initializer => $expr,
                              condition   => $cond,
                              step        => $incr,
                              block       => $block,
                              } );

            $self->_leave_scope;

            return $for;
        } else {
            Carp::confess $sep->[0], ' ', $sep->[1];
        }
    } elsif( $token->[0] eq 'ID' && (    $token->[1] eq 'my'
                                      || $token->[1] eq 'our'
                                      || $token->[1] eq 'state' ) ) {
        $foreach_var = _parse_lexical_variable( $self, $token->[1] )
    } elsif( $token->[0] eq 'DOLLAR' ) {
        my $id = $self->lexer->lex_identifier;
        $foreach_var = _find_symbol( $self, '$', $id->[1] );
    } else {
        Carp::confess $token->[0], ' ', $token->[1];
    }

    # if we get there it is not C-style for
    if( !$foreach_expr ) {
        _lex_token( $self, 'OPPAR' );
        $foreach_expr = _parse_expr( $self );
        _lex_token( $self, 'CLPAR' );
    }

    $self->_add_pending_lexicals;
    _lex_token( $self, 'OPBRK' );

    my $block = _parse_block_rest( $self, 1 );

    my $for = Language::P::ParseTree::Foreach->new
                  ( { expression => $foreach_expr,
                      block      => $block,
                      variable   => $foreach_var,
                      } );

    $self->_leave_scope;

    return $for;
}

sub _parse_while {
    my( $self ) = @_;
    my $keyword = _lex_token( $self, 'ID' );

    _lex_token( $self, 'OPPAR' );

    $self->_enter_scope;
    my $expr = _parse_expr( $self );
    $self->_add_pending_lexicals;

    _lex_token( $self, 'CLPAR' );
    _lex_token( $self, 'OPBRK' );

    my $block = _parse_block_rest( $self, 1 );

    my $while = Language::P::ParseTree::ConditionalLoop
                    ->new( { condition  => $expr,
                             block      => $block,
                             block_type => $keyword->[1],
                             } );

    $self->_leave_scope;

    return $while;
}

sub _parse_sideff {
    my( $self ) = @_;
    my $expr = _parse_expr( $self );
    my $keyword = $self->lexer->peek( X_TERM );

    if( $keyword->[0] eq 'ID' && $keyword->[2] == T_KEYWORD ) {
        if( $keyword->[1] eq 'if' || $keyword->[1] eq 'unless' ) {
            _lex_token( $self, 'ID' );
            my $cond = _parse_expr( $self );

            $expr = Language::P::ParseTree::Conditional->new
                        ( { iftrues => [ [ $keyword->[1], $cond, $expr ] ],
                            } );
        } elsif( $keyword->[1] eq 'while' || $keyword->[1] eq 'until' ) {
            _lex_token( $self, 'ID' );
            my $cond = _parse_expr( $self );

            $expr = Language::P::ParseTree::ConditionalLoop->new
                        ( { condition  => $cond,
                            block      => $expr,
                            block_type => $keyword->[1],
                            } );
        } elsif( $keyword->[1] eq 'for' || $keyword->[1] eq 'foreach' ) {
            _lex_token( $self, 'ID' );
            my $cond = _parse_expr( $self );

            $expr = Language::P::ParseTree::Foreach->new
                        ( { expression => $cond,
                            block      => $expr,
                            variable   => _find_symbol( $self, '$', '_' ),
                            } );
        }
    }

    return $expr;
}

sub _parse_expr {
    my( $self ) = @_;
    my $expr = _parse_term( $self, PREC_LOWEST );
    my $la = $self->lexer->peek( X_TERM );

    if( $la->[0] eq 'COMMA' ) {
        my $terms = _parse_cslist_rest( $self, PREC_LOWEST,
                                        [ -1, -1, '@' ], 0, $expr );

        return Language::P::ParseTree::List->new( { expressions => $terms } );
    }

    return $expr;
}

sub _find_symbol {
    my( $self, $sigil, $name ) = @_;

    die if $name =~ /::/;

    my( $crossed_sub, $slot ) = $self->_lexicals->find_name( $sigil . $name );

    if( $slot ) {
        $slot->{in_pad} ||= $crossed_sub ? 1 : 0;

        return Language::P::ParseTree::LexicalSymbol->new
                   ( { name  => $name,
                       sigil => $sigil,
                       slot  => { level => $crossed_sub,
                                  slot  => $slot,
                                  },
                       } );
    }

    return Language::P::ParseTree::Symbol->new( { name  => $name,
                                                  sigil => $sigil,
                                                  } );
}

sub _parse_maybe_subscripts {
    my( $self, $sigil, $is_id, $token ) = @_;

    # can't be slice/element
    if( $is_id  && $sigil ne '@' && $sigil ne '$' ) {
        return _find_symbol( $self, $sigil, $token->[1] );
    }

    my $next = $self->lexer->peek( X_OPERATOR );

    # array/hash slice
    if( $sigil eq '@' && ( $next->[0] eq 'OPBRK' || $next->[0] eq 'OPSQ' ) ) {
        my( undef, $subscript ) = _parse_bracketed_expr( $self, $next->[0] );

        my $sym_sigil = $next->[0] eq 'OPBRK' ? '%' : '@';
        my $subscripted = $is_id ? _find_symbol( $self, $sym_sigil,
                                                 $token->[1] ) :
                                   $token;

        return Language::P::ParseTree::Slice->new
                   ( { subscripted => $subscripted,
                       subscript   => $subscript,
                       type        => $next->[1],
                       reference   => $subscripted->isa( 'Language::P::ParseTree::Symbol' ) ? 0 : 1,
                       } );
    }

    if( $next->[0] eq 'ARROW' ) {
        my $subscripted = $is_id ? _find_symbol( $self, $sigil, $token->[1] ) :
                                   $token;

        return _parse_maybe_subscript_rest( $self, $subscripted );
    } elsif(    $sigil eq '$'
             && (    $next->[0] eq 'OPBRK'
                  || $next->[0] eq 'OPSQ' ) ) {
        my( undef, $subscript ) = _parse_bracketed_expr( $self, $next->[0] );

        my $sym_sigil = $next->[0] eq 'OPBRK' ? '%' : '@';
        my $subscripted = $is_id ? _find_symbol( $self, $sym_sigil,
                                                 $token->[1] ) :
                                   $token;

        my $term = Language::P::ParseTree::Subscript->new
                       ( { subscripted => $subscripted,
                           subscript   => $subscript,
                           type        => $next->[1],
                           reference   => $subscripted->isa( 'Language::P::ParseTree::Symbol' ) ? 0 : 1,
                           } );

        return _parse_maybe_subscript_rest( $self, $term );
    }

    # not a subscripted expression, just return the token
    return $is_id ? _find_symbol( $self, $sigil, $token->[1] ) :
                    $token;
}

sub _parse_maybe_subscript_rest {
    my( $self, $subscripted ) = @_;
    my $next = $self->lexer->peek( X_OPERATOR );

    # array/hash element
    if( $next->[0] eq 'ARROW' ) {
        _lex_token( $self, 'ARROW' );
        my $bracket = $self->lexer->peek;

        if(    $bracket->[0] eq 'OPPAR'
            || $bracket->[0] eq 'OPSQ'
            || $bracket->[0] eq 'OPBRK' ) {
            return _parse_dereference_rest( $self, $subscripted, $bracket );
        } else {
            return _parse_maybe_direct_method_call( $self, $subscripted );
        }
    } elsif(    $next->[0] eq 'OPPAR'
             || $next->[0] eq 'OPSQ'
             || $next->[0] eq 'OPBRK' ) {
        return _parse_dereference_rest( $self, $subscripted, $next );
    } else {
        return $subscripted;
    }
}

sub _parse_dereference_rest {
    my( $self, $subscripted, $bracket ) = @_;
    my $term;

    if( $bracket->[0] eq 'OPPAR' ) {
        _lex_token( $self, 'OPPAR' );
        ( my $args, undef ) = _parse_arglist( $self, PREC_LOWEST, [-1, -1, '@'], 0 );
        _lex_token( $self, 'CLPAR' );
        my $func = Language::P::ParseTree::UnOp->new
                       ( { left => $subscripted,
                           op   => '&',
                           } );
        $term = Language::P::ParseTree::FunctionCall->new
                    ( { function    => $func,
                        arguments   => $args,
                        } );
    } else {
        my( undef, $subscript ) = _parse_bracketed_expr( $self, $bracket->[0] );
        $term = Language::P::ParseTree::Subscript->new
                    ( { subscripted => $subscripted,
                        subscript   => $subscript,
                        type        => $bracket->[1],
                        reference   => 1,
                        } );
    }

    return _parse_maybe_subscript_rest( $self, $term );
}

sub _parse_bracketed_expr {
    my( $self, $bracket ) = @_;

    _lex_token( $self, $bracket );
    # allow empty () for function call
    if( $bracket eq 'OPPAR' ) {
        my $next = $self->lexer->peek( X_TERM );
        if( $next->[0] eq 'CLPAR' ) {
            _lex_token( $self, 'CLPAR' );
            return ( $bracket, undef );
        }
    }
    my $subscript = _parse_expr( $self );
    _lex_token( $self, $bracket eq 'OPBRK' ? 'CLBRK' :
                       $bracket eq 'OPSQ'  ? 'CLSQ' :
                                             'CLPAR' );

    return ( $bracket, $subscript );
}

sub _parse_maybe_indirect_method_call {
    my( $self, $op, $next ) = @_;
    my $indir = _parse_indirobj( $self, 1 );

    if( $indir ) {
        # if FH -> no method
        # proto FH -> no method
        # Foo $bar (?) -> no method
        # foo $bar -> method
        # print xxx .... -> no method
        if( $op->[1] eq 'print' ) {
            my $la = 1;
        }
        # foo pack:: -> method

        use Data::Dumper;
        Carp::confess Dumper( $indir ) . ' ';
    }

    return Language::P::ParseTree::Bareword->new
               ( { value => $op->[1],
                   } );
}

sub _parse_maybe_direct_method_call {
    my( $self, $invocant ) = @_;
    my $token = $self->lexer->lex( X_TERM );

    if( $token->[0] eq 'ID' ) {
        my $oppar = $self->lexer->peek( X_OPERATOR );
        my $args;
        if( $oppar->[0] eq 'OPPAR' ) {
            ( undef, $args ) = _parse_bracketed_expr( $self, 'OPPAR' );
        }

        my $term = Language::P::ParseTree::MethodCall->new
                       ( { invocant  => $invocant,
                           method    => $token->[1],
                           arguments => $args,
                           indirect  => 0,
                           } );

        return _parse_maybe_subscript_rest( $self, $term );
    } elsif( $token->[0] eq 'DOLLAR' ) {
        my $id = _lex_token( $self, 'ID' );
        my $meth = _find_symbol( $self, '$', $id->[1] );
        my $oppar = $self->lexer->peek( X_OPERATOR );
        my $args;
        if( $oppar->[0] eq 'OPPAR' ) {
            ( undef, $args ) = _parse_bracketed_expr( $self, 'OPPAR' );
        }

        my $term = Language::P::ParseTree::MethodCall->new
                       ( { invocant  => $invocant,
                           method    => $meth,
                           arguments => $args,
                           indirect  => 1,
                           } );

        return _parse_maybe_subscript_rest( $self, $term );
    } else {
        die $token->[0], ' ', $token->[1];
    }
}

sub _parse_match {
    my( $self, $token ) = @_;

    if( $token->[6] ) {
        my $string = _parse_string_rest( $self, $token );
        my $match = Language::P::ParseTree::InterpolatedPattern->new
                        ( { string     => $string,
                            op         => $token->[1],
                            flags      => $token->[5],
                            } );

        return $match;
    } else {
        my $terminator = $token->[2];
        my $interpolate = $terminator eq "'" ? 0 : 1;

        my $parts = Language::P::Parser::Regex->new
                        ( { generator   => $self->generator,
                            runtime     => $self->runtime,
                            interpolate => $interpolate,
                            } )->parse_string( $token->[3] );
    my $match = Language::P::ParseTree::Pattern->new
                    ( { components => $parts,
                        op         => $token->[1],
                        flags      => $token->[5],
                        } );

        return $match;
    }
}

sub _parse_substitution {
    my( $self, $token ) = @_;
    my $match = _parse_match( $self, $token );

    my $replace;
    if( $match->flags && grep $_ eq 'e', @{$match->flags} ) {
        local $self->{lexer} = Language::P::Lexer->new
                                   ( { string => $token->[4]->[3] } );
        $replace = _parse_block_rest( $self, 1, 'SPECIAL' );
    } else {
        $replace = _parse_string_rest( $self, $token->[4] );
    }

    my $sub = Language::P::ParseTree::Substitution->new
                  ( { pattern     => $match,
                      replacement => $replace,
                      } );

    return $sub;
}

sub _parse_string_rest {
    my( $self, $token ) = @_;
    my( $quote, $terminator ) = ( $token->[1], $token->[2] );
    my $interpolate = $quote eq 'qq'     ? 1 :
                      $quote eq 'q'      ? 0 :
                      $quote eq 'qw'     ? 0 :
                      $terminator eq "'" ? 0 :
                                           1;
    my @values;
    local $self->{lexer} = Language::P::Lexer->new( { string => $token->[3] } );

    $self->lexer->quote( { interpolate => $interpolate,
                           pattern     => 0,
                           } );
    for(;;) {
        my $value = $self->lexer->lex_quote;

        if( $value->[0] eq 'STRING' ) {
            push @values,
                Language::P::ParseTree::Constant->new( { type  => 'string',
                                                         value => $value->[1],
                                                         } );
        } elsif( $value->[0] eq 'SPECIAL' ) {
            last;
        } elsif( $value->[0] eq 'DOLLAR' || $value->[0] eq 'AT' ) {
            push @values, _parse_indirobj_maybe_subscripts( $self, $value );
        } else {
            die $value->[0], ' ', $value->[1];
        }
    }

    $self->lexer->quote( undef );

    my $string;
    if(    @values == 1
        && $values[0]->isa( 'Language::P::ParseTree::Constant' ) ) {

        $string = $values[0];
    } elsif( @values == 0 ) {
        $string = Language::P::ParseTree::Constant->new( { value => "",
                                                           type  => 'string',
                                                           } );
    } else {
        $string = Language::P::ParseTree::QuotedString->new
                      ( { components => \@values,
                           } );
    }

    if( $quote eq '`' || $quote eq 'qx' ) {
        $string = Language::P::ParseTree::UnOp->new
                      ( { op   => 'backtick',
                          left => $string,
                          } );
    } elsif( $quote eq 'qw' ) {
        my @words = map Language::P::ParseTree::Constant->new
                            ( { value => $_,
                                type  => 'string',
                                } ),
                        split /[\s\r\n]+/, $string->value;

        $string = Language::P::ParseTree::List->new
                      ( { expressions => \@words,
                          } );
    }

    return $string;
}

sub _parse_term_terminal {
    my( $self, $token, $is_bind ) = @_;

    if( $token->[0] eq 'QUOTE' ) {
        my $qstring = _parse_string_rest( $self, $token );

        if( $token->[1] eq '<' ) {
            # simple scalar: readline, anything else: glob
            if(    $qstring->isa( 'Language::P::ParseTree::QuotedString' )
                && $#{$qstring->components} == 0
                && $qstring->components->[0]
                           ->isa( 'Language::P::ParseTree::Symbol' ) ) {
                return Language::P::ParseTree::Overridable
                           ->new( { function  => 'readline',
                                    arguments => [ $qstring->components->[0] ] } );
            } elsif( $qstring->isa( 'Language::P::ParseTree::Constant' ) ) {
                if( $qstring->value =~ /^[a-zA-Z_]/ ) {
                    # FIXME simpler method, make lex_identifier static
                    my $lexer = Language::P::Lexer->new
                                    ( { string => $qstring->value } );
                    my $id = $lexer->lex_identifier;

                    if( $id && !length( ${$lexer->buffer} ) ) {
                        my $glob = Language::P::ParseTree::Symbol->new
                                       ( { name  => $id->[1],
                                           sigil => '*',
                                           } );
                        return Language::P::ParseTree::Overridable
                                   ->new( { function  => 'readline',
                                            arguments => [ $glob ],
                                            } );
                    }
                }
                return Language::P::ParseTree::Glob
                           ->new( { arguments => [ $qstring ] } );
            } else {
                return Language::P::ParseTree::Glob
                           ->new( { arguments => [ $qstring ] } );
            }
        }

        return $qstring;
    } elsif( $token->[0] eq 'PATTERN' ) {
        my $pattern;
        if( $token->[1] eq 'm' || $token->[1] eq 'qr' ) {
            $pattern = _parse_match( $self, $token );
        } elsif( $token->[1] eq 's' ) {
            $pattern = _parse_substitution( $self, $token );
        } else {
            die;
        }

        if( !$is_bind && $token->[1] ne 'qr' ) {
            $pattern = Language::P::ParseTree::BinOp->new
                           ( { op    => '=~',
                               left  => _find_symbol( $self, '$', '_' ),
                               right => $pattern,
                               } );
        }

        return $pattern;
    } elsif( $token->[0] eq 'NUMBER' ) {
        return Language::P::ParseTree::Number->new( { value => $token->[1],
                                                      flags => $token->[2],
                                                      } );
    } elsif( $token->[1] eq '$#' || $token->[1] =~ /[\*\$%@&]/ ) {
        return _parse_indirobj_maybe_subscripts( $self, $token );
    } elsif(    $token->[0] eq 'ID' && $token->[2] == T_KEYWORD
             && (    $token->[1] eq 'my' || $token->[1] eq 'our'
                  || $token->[1] eq 'state' ) ) {
        return _parse_lexical( $self, $token->[1] );
    } elsif( $token->[0] eq 'ID' ) {
        my $next = $self->lexer->peek( X_OPERATOR );

        if( $next->[0] eq 'COMMA' && $next->[1] eq '=>' ) {
            # quoted by fat arrow
            return Language::P::ParseTree::Constant->new
                       ( { value => $token->[1],
                           type  => 'string',
                           } );
        }

        return _parse_listop( $self, $token );
    }

    return undef;
}

sub _parse_indirobj_maybe_subscripts {
    my( $self, $token ) = @_;
    my $indir = _parse_indirobj( $self, 0 );

    if( ref( $indir ) eq 'ARRAY' && $indir->[0] eq 'ID' ) {
        return _parse_maybe_subscripts( $self, $token->[1], 1, $indir );
    } else {
        my $deref = Language::P::ParseTree::UnOp->new
                        ( { left  => $indir,
                            op    => $token->[1],
                            } );

        return _parse_maybe_subscripts( $self, $token->[1], 0, $deref );
    }
}

sub _parse_lexical {
    my( $self, $keyword ) = @_;

    die $keyword unless $keyword eq 'my' || $keyword eq 'our';

    my $list = _parse_lexical_rest( $self, $keyword );

    return $list;
}

sub _parse_lexical_rest {
    my( $self, $keyword ) = @_;

    my $token = $self->lexer->peek( X_TERM );

    if( $token->[0] eq 'OPPAR' ) {
        my @variables;

        _lex_token( $self, 'OPPAR' );

        for(;;) {
            push @variables, _parse_lexical_variable( $self, $keyword );
            my $token = $self->lexer->peek( X_OPERATOR );

            if( $token->[0] eq 'COMMA' ) {
                _lex_token( $self, 'COMMA' );
            } elsif( $token->[0] eq 'CLPAR' ) {
                _lex_token( $self, 'CLPAR' );
                last;
            }
        }

        push @{$self->_pending_lexicals}, @variables;

        return Language::P::ParseTree::List->new( { expressions => \@variables } );
    } else {
        my $variable = _parse_lexical_variable( $self, $keyword );

        push @{$self->_pending_lexicals}, $variable;

        return $variable;
    }
}

sub _parse_lexical_variable {
    my( $self, $keyword ) = @_;
    my $sigil = $self->lexer->lex( X_TERM );

    die $sigil->[0], ' ', $sigil->[1] unless $sigil->[1] =~ /^[\$\@\%]$/;

    my $name = $self->lexer->lex_identifier;
    die unless $name;

    # FIXME our() variable refers to package it was declared in
    return Language::P::ParseTree::LexicalDeclaration->new
               ( { name             => $name->[1],
                   sigil            => $sigil->[1],
                   declaration_type => $keyword,
                   } );
}

sub _parse_term_p {
    my( $self, $prec, $token, $lookahead, $is_bind ) = @_;
    my $terminal = _parse_term_terminal( $self, $token, $is_bind );

    return $terminal if $terminal && !$lookahead;

    if( $terminal ) {
        my $la = $self->lexer->peek( X_OPERATOR );

        if( !$prec_assoc_bin{$la->[1]} || $prec_assoc_bin{$la->[1]}[0] > $prec ) {
            return $terminal;
        } elsif( $la->[0] eq 'INTERR' ) {
            _lex_token( $self, 'INTERR' );
            return _parse_ternary( $self, $prec_assoc_bin{$la->[1]}[0],
                                   $terminal );
        } elsif( $prec_assoc_bin{$la->[1]} ) {
            return _parse_term_n( $self, $prec_assoc_bin{$la->[1]}[0],
                                  $terminal );
        } else {
            Carp::confess $la->[0], ' ', $la->[1];
        }
    } elsif( $prec_assoc_un{$token->[1]} ) {
        my $rest = _parse_term_n( $self, $prec_assoc_un{$token->[1]}[0] );

        return Language::P::ParseTree::UnOp->new( { op    => $token->[1],
                                                    left  => $rest,
                                                    } );
    } elsif( $token->[0] eq 'OPPAR' ) {
        my $term = _parse_expr( $self );
        my $clpar = $self->lexer->lex( X_TERM );

        die $clpar->[0], ' ', $clpar->[1]
          unless $clpar->[0] eq 'CLPAR';

        return $term;
    }

    return undef;
}

sub _parse_ternary {
    my( $self, $prec, $terminal ) = @_;

    my $iftrue = _parse_term_n( $self, PREC_TERNARY_COLON - 1 );
    _lex_token( $self, 'COLON' );
    my $iffalse = _parse_term_n( $self, $prec - 1 );

    return Language::P::ParseTree::Ternary->new
               ( { condition => $terminal,
                   iftrue    => $iftrue,
                   iffalse   => $iffalse,
                   } );
}

sub _parse_term_n {
    my( $self, $prec, $terminal, $is_bind ) = @_;

    if( !$terminal ) {
        my $token = $self->lexer->lex( X_TERM );
        $terminal = _parse_term_p( $self, $prec, $token, undef, $is_bind );

        if( !$terminal ) {
            $self->lexer->unlex( $token );
            return undef;
        }
    }

    for(;;) {
        my $token = $self->lexer->lex( X_OPERATOR );
        my $bin = $prec_assoc_bin{$token->[1]};
        if( !$bin || $bin->[0] > $prec ) {
            $self->lexer->unlex( $token );
            last;
        } elsif( $token->[0] eq 'INTERR' ) {
            $terminal = _parse_ternary( $self, $bin->[0], $terminal );
        } else {
            # do not try to use colon as binary
            Carp::confess $token->[0], ' ', $token->[1]
                if $token->[0] eq 'COLON';

            my $q = $bin->[1] eq 'RIGHT' ? $bin->[0] : $bin->[0] - 1;
            my $rterm = _parse_term_n( $self, $q, undef,
                                       (    $token->[0] eq 'MATCH'
                                         || $token->[0] eq 'NOMATCH' ) );

            $terminal = Language::P::ParseTree::BinOp->new
                            ( { op    => $token->[1],
                                left  => $terminal,
                                right => $rterm,
                                } );
        }
    }

    return $terminal;
}

sub _parse_term {
    my( $self, $prec ) = @_;
    my $token = $self->lexer->lex( X_TERM );
    my $terminal = _parse_term_p( $self, $prec, $token, 1, 0 );

    if( $terminal ) {
        $terminal = _parse_term_n( $self, $prec, $terminal );

        return $terminal;
    }

    $self->lexer->unlex( $token );

    return undef;
}

sub _parse_block_rest {
    my( $self, $open_scope, $end_token ) = @_;

    $end_token ||= 'CLBRK';
    $self->_enter_scope if $open_scope;

    my @lines;
    for(;;) {
        my $token = $self->lexer->lex( X_STATE );
        if( $token->[0] eq $end_token ) {
            $self->_leave_scope if $open_scope;
            return Language::P::ParseTree::Block->new( { lines => \@lines } );
        } else {
            $self->lexer->unlex( $token );
            my $line = _parse_line( $self );

            push @lines, $line;
        }
    }
}

sub _parse_indirobj {
    my( $self, $allow_fail ) = @_;
    my $id = $self->lexer->lex_identifier;

    if( $id ) {
        return $id;
    }

    my $token = $self->lexer->lex( X_TERM );

    if( $token->[0] eq 'OPBRK' ) {
        my $block = _parse_block_rest( $self, 1 );

        return $block;
    } elsif( $token->[0] eq 'DOLLAR' ) {
        my $indir = _parse_indirobj( $self, 0 );

        if( ref( $indir ) eq 'ARRAY' && $indir->[0] eq 'ID' ) {
            return _find_symbol( $self, '$', $indir->[1] );
        } else {
            return Language::P::ParseTree::UnOp->new
                       ( { left  => $indir,
                           op    => $token->[1],
                           } );
        }
    } elsif( $allow_fail ) {
        $self->lexer->unlex( $token );

        return undef;
    } else {
        die $token->[0], ' ', $token->[1];
    }
}

sub _declared_id {
    my( $self, $op ) = @_;
    my $call;

    my $is_print = $op->[1] eq 'print';
    if( $op->[2] == T_OVERRIDABLE ) {
        my $st = $self->runtime->symbol_table;

        if( $st->get_symbol( $op->[1], '&' ) ) {
            die "Overriding '$op->[1]' not implemented";
        }
        $call = Language::P::ParseTree::Overridable->new
                    ( { function  => $op->[1],
                        } );

        return ( $call, 1 );
    } elsif( $is_print ) {
        $call = Language::P::ParseTree::Print->new
                    ( { function  => $op->[1],
                        } );

        return ( $call, 1 );
    } elsif( $op->[2] == T_KEYWORD ) {
        $call = Language::P::ParseTree::Builtin->new
                    ( { function  => $op->[1],
                        } );

        return ( $call, 1 );
    } else {
        my $st = $self->runtime->symbol_table;

        if( $st->get_symbol( $op->[1], '&' ) ) {
            return ( undef, 1 );
        }
    }

    return ( undef, 0 );
}

sub _parse_listop {
    my( $self, $op ) = @_;
    my $next = $self->lexer->peek( X_TERM );

    my $is_print = $op->[1] eq 'print';
    my( $call, $declared ) = _declared_id( $self, $op );
    my( $args, $fh );

    if( !$call || !$declared ) {
        my $st = $self->runtime->symbol_table;

        if( $next->[0] eq 'ARROW' ) {
            _lex_token( $self, 'ARROW' );
            my $la = $self->lexer->peek( X_TERM );

            if( $la->[0] eq 'ID' || $la->[0] eq 'DOLLAR' ) {
                # here we are calling the method on a bareword
                my $invocant = Language::P::ParseTree::Constant->new
                                   ( { value => $op->[1],
                                       type  => 'string',
                                       } );

                return _parse_maybe_direct_method_call( $self, $invocant );
            } else {
                # looks like a bareword, report as such
                $self->lexer->unlex( $next );

                return Language::P::ParseTree::Bareword->new
                           ( { value => $op->[1],
                               } );
            }
        } elsif( !$declared && $next->[0] ne 'OPPAR' ) {
            # not a declared subroutine, nor followed by parenthesis
            # try to see if it is some sort of (indirect) method call
            return _parse_maybe_indirect_method_call( $self, $op, $next );
        }

        # foo Bar:: is always a method call
        if(    $next->[0] eq 'ID'
            && $st->get_package( $next->[1] ) ) {
            return _parse_maybe_indirect_method_call( $self, $op, $next );
        }

        $call = Language::P::ParseTree::FunctionCall->new
                    ( { function  => $op->[1],
                        arguments => undef,
                        } );
    }

    my $proto = $call->parsing_prototype;
    if( $next->[0] eq 'OPPAR' ) {
        $self->lexer->lex; # comsume token
        ( $args, $fh ) = _parse_arglist( $self, PREC_LOWEST, $proto, 0 );
        my $cl = $self->lexer->lex( X_OPERATOR );

        die $cl->[0], ' ', $cl->[1] unless $cl->[0] eq 'CLPAR';
    } elsif( $proto->[1] != 0 ) {
        Carp::confess( "Undeclared identifier '$op->[1]'" ) unless $declared;
        ( $args, $fh ) = _parse_arglist( $self, PREC_LISTOP, $proto, 0 );
    }

    $call->{arguments} = $args;
    $call->{filehandle} = $fh if $fh;

    return $call;
}

sub _parse_arglist {
    my( $self, $prec, $proto, $index ) = @_;
    my $la = $self->lexer->peek( X_TERM );

    my $term;
    my $indirect_filehandle = $index == 0 && $proto->[2] eq '!';
    ++$index if $indirect_filehandle;
    if( $la->[0] eq 'ID' && $indirect_filehandle ) {
        my( $call, $declared ) = _declared_id( $self, $la );

        if( !$declared ) {
            _lex_token( $self, 'ID' );
            $term = Language::P::ParseTree::Symbol->new
                        ( { name  => $la->[1],
                            sigil => '*',
                            } );
        } else {
            $indirect_filehandle = 0;
        }
    } elsif( $indirect_filehandle ) {
        $indirect_filehandle = 0;
    }

    if( !$term ) {
        $term = _maybe_handle( _parse_term( $self, $prec ),
                               $proto, $index );
        ++$index;
    }

    return unless $term;
    return [ $term ] if $proto->[1] == $index;

    if( $indirect_filehandle ) {
        my $la = $self->lexer->peek( X_TERM );

        if( $la->[0] eq 'COMMA' ) {
            return _parse_cslist_rest( $self, $prec, $proto, $index, $term );
        } else {
            return ( _parse_arglist( $self, $prec, $proto, $index ), $term );
        }
    }

    return _parse_cslist_rest( $self, $prec, $proto, $index, $term );
}

sub _parse_cslist_rest {
    my( $self, $prec, $proto, $index, @terms ) = @_;

    for(; $proto->[1] != $index;) {
        my $comma = $self->lexer->lex( X_TERM );
        if( $comma->[0] eq 'COMMA' ) {
            my $term = _maybe_handle( _parse_term( $self, $prec ),
                                      $proto, $index );
            push @terms, $term;
            ++$index;
        } else {
            $self->lexer->unlex( $comma );
            last;
        }
    }

    return \@terms;
}

sub _maybe_handle {
    my( $term, $proto, $index ) = @_;

    return $term if !$term || !$term->is_bareword;
    return $term if $index + 2 > $#$proto || $proto->[$index + 2] ne '*';

    return Language::P::ParseTree::Symbol->new
               ( { name  => $term->value,
                   sigil => '*',
                   } );
}

1;
