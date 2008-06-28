package Language::P::Parser;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Language::P::Lexer qw(:all);
use Language::P::ParseTree;
use Language::P::Value::ScratchPad;
use Language::P::Value::Code;

__PACKAGE__->mk_ro_accessors( qw(lexer generator runtime) );
__PACKAGE__->mk_accessors( qw(_package _lexicals _pending_lexicals
                              _current_sub) );

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

    $self->_pending_lexicals( [] );
    $self->_lexicals( undef );
    $self->_enter_scope( 0 , 1 ); # FIXME eval

    my $code = Language::P::Value::Code->new( { bytecode => [],
                                                 lexicals => $self->_lexicals } );
    $self->generator->push_code( $code );
    $self->_current_sub( $code );

    while( my $line = _parse_line( $self ) ) {
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
        die $token->[0], ' ', $token->[1];
    }

    return $token;
}

sub _lex_semicolon {
    my( $self ) = @_;
    my $token = $self->lexer->lex;

    if(    ( $token->[0] eq 'SPECIAL' && $token->[1] eq 'EOF' )
        || ( $token->[0] eq 'SEMICOLON' ) ) {
        return;
    }

    die $token->[0], ' ', $token->[1];
}

sub _parse_line {
    my( $self ) = @_;

    my $label = _label( $self );
    my $token = $self->lexer->peek( X_STATE );

    if(    $token->[0] ne 'KEYWORD'
        || (    $token->[1] eq 'my' || $token->[1] eq 'our'
             || $token->[1] eq 'state' ) ) {
        my $sideff = _parse_sideff( $self );
        _lex_semicolon( $self );

        $self->_add_pending_lexicals;

        return $sideff;
    } elsif( $token->[1] eq 'sub' ) {
        return _parse_sub( $self, 1 | 2 );
    } elsif( $token->[1] eq 'if' || $token->[1] eq 'unless' ) {
        return _parse_cond( $self );
    }

    die $token->[0];
}

sub _add_pending_lexicals {
    my( $self ) = @_;

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
    my( $self, $flags ) = @_;
    _lex_token( $self, 'KEYWORD' ); # sub
    my $name = $self->lexer->peek( X_NOTHING );

    # TODO prototypes
    if( $name->[0] eq 'ID' ) {
        die 'Syntax error: named sub' unless $flags & 1;
        _lex_token( $self, 'ID' );
        _lex_token( $self, 'OPBRK' );
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
    # add @_
    # FIXME incestuos with runtime
    my $args_slot = $self->_lexicals->add_name( '@', '_' );
    $args_slot->{index} = $self->_lexicals->add_value;

    $self->_current_sub( $sub );
    my $block = _parse_block_rest( $self, 0 );
    $sub->{lines} = $block->{lines}; # FIXME encapsulation
    $self->_leave_scope;
    $self->_current_sub( $sub->outer );

    return $sub;
}

sub _parse_cond {
    my( $self ) = @_;
    my $cond = _lex_token( $self, 'KEYWORD' );

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
        last if    $else->[0] ne 'KEYWORD'
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

sub _parse_sideff {
    my( $self ) = @_;
    my $expr = _parse_expr( $self );

    return $expr;
}

sub _parse_expr {
    my( $self ) = @_;
    my $expr = _parse_term( $self );
    my $la = $self->lexer->peek( X_TERM );

    if( $la->[0] eq 'COMMA' ) {
        my $terms = _parse_cslist_rest( $self, $expr );

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
                           reference   => 0,
                           } );

        return _parse_maybe_subscript_rest( $self, $term );
    }
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
            my( undef, $subscript ) = _parse_bracketed_expr( $self, $bracket->[0] );

            my $term = Language::P::ParseTree::Subscript->new
                           ( { subscripted => $subscripted,
                               subscript   => $subscript,
                               type        => $bracket->[1],
                               reference   => 1,
                               } );

            return _parse_maybe_subscript_rest( $self, $term );
        } else {
            return _parse_maybe_method_call( $self, $subscripted );
        }
    } elsif(    $next->[0] eq 'OPPAR'
             || $next->[0] eq 'OPSQ'
             || $next->[0] eq 'OPBRK' ) {
        my( undef, $subscript ) = _parse_bracketed_expr( $self, $next->[0] );

        my $term = Language::P::ParseTree::Subscript->new
                       ( { subscripted => $subscripted,
                           subscript   => $subscript,
                           type        => $next->[1],
                           reference   => 1,
                           } );

        return _parse_maybe_subscript_rest( $self, $term );
    } else {
        return $subscripted;
    }
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

sub _parse_maybe_method_call {
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

sub _parse_term_terminal {
    my( $self, $token ) = @_;

    if( $token->[0] eq 'STRING' ) {
        return Language::P::ParseTree::Constant->new( { type  => 'string',
                                                        value => $token->[1],
                                                        } );
    } elsif( $token->[0] eq 'NUMBER' ) {
        return Language::P::ParseTree::Constant->new( { type  => 'number',
                                                        value => $token->[1],
                                                        } );
    } elsif( $token->[1] eq '$#' || $token->[1] =~ /[\*\$%@&]/ ) {
        my $indir = _parse_indirobj( $self );

        if( ref( $indir ) eq 'ARRAY' && $indir->[0] eq 'ID' ) {
            return _parse_maybe_subscripts( $self, $token->[1], 1, $indir );
        } else {
            my $deref = Language::P::ParseTree::UnOp->new
                            ( { left  => $indir,
                                op    => $token->[1],
                                } );

            return _parse_maybe_subscripts( $self, $token->[1], 0, $deref );
        }
    } elsif(    $token->[0] eq 'KEYWORD'
             && (    $token->[1] eq 'my' || $token->[1] eq 'our'
                  || $token->[1] eq 'state' ) ) {
        return _parse_lexical( $self, $token->[1] );
    } elsif( $token->[0] eq 'ID' ) {
        $self->lexer->unlex( $token );
        return _parse_listop( $self );
    }

    return undef;
}

sub _parse_lexical {
    my( $self, $keyword ) = @_;

    die unless $keyword eq 'my';

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

    my $name = _lex_token( $self, 'ID' );

    return Language::P::ParseTree::LexicalDeclaration->new
               ( { name             => $name->[1],
                   sigil            => $sigil->[1],
                   declaration_type => $keyword,
                   } );
}

my %prec_assoc_bin =
  ( '->'  => [ 2,  'LEFT' ],
    '**'  => [ 4,  'RIGHT' ],
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
    # 18, ternary
    '='   => [ 19, 'RIGHT' ],
    '+='  => [ 19, 'RIGHT' ],
    '-='  => [ 19, 'RIGHT' ],
    '*='  => [ 19, 'RIGHT' ],
    '/='  => [ 19, 'RIGHT' ],
    );

my %prec_assoc_un =
  ( '+'   => [ 5,  'RIGHT' ],
    '-'   => [ 5,  'RIGHT' ],
    );

$_->[0] = 999 - $_->[0] foreach values %prec_assoc_bin;

sub _parse_term_p {
    my( $self, $token, $lookahead ) = @_;
    my $terminal = _parse_term_terminal( $self, $token );

    return $terminal if $terminal && !$lookahead;

    if( $terminal ) {
        my $la = $self->lexer->peek( X_OPERATOR );

        if( $prec_assoc_bin{$la->[1]} ) {
            return _parse_term_n( $self, $prec_assoc_bin{$la->[1]}[0],
                                  $terminal );
        } else {
            return $terminal;
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

sub _parse_term_n {
    my( $self, $prec, $terminal ) = @_;

    if( !$terminal ) {
        my $token = $self->lexer->lex( X_TERM );
        $terminal = _parse_term_p( $self, $token );

        if( !$terminal ) {
            $self->lexer->unlex( $token );
            return undef;
        }
    }

    for(;;) {
        my $token = $self->lexer->lex( X_OPERATOR );
        my $bin = $prec_assoc_bin{$token->[1]};
        if( !$bin || $bin->[0] < $prec ) {
            $self->lexer->unlex( $token );
            last;
        }
        my $q = $bin->[1] eq 'RIGHT' ? $bin->[0] : $bin->[0] + 1;
        my $rterm = _parse_term_n( $self, $q );

        $terminal = Language::P::ParseTree::BinOp->new( { op    => $token->[1],
                                                          left  => $terminal,
                                                          right => $rterm,
                                                          } );
    }

    return $terminal;
}

sub _parse_term {
    my( $self ) = @_;
    my $token = $self->lexer->lex( X_TERM );
    my $terminal = _parse_term_p( $self, $token, 1 );

    if( $terminal ) {
        $terminal = _parse_term_n( $self, 0, $terminal );

        return $terminal;
    }

    return undef;
}

sub _parse_block_rest {
    my( $self, $open_scope ) = @_;

    $self->_enter_scope if $open_scope;

    my @lines;
    for(;;) {
        my $token = $self->lexer->lex( X_STATE );
        if( $token->[0] eq 'CLBRK' ) {
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
    my( $self ) = @_;
    my $token = $self->lexer->lex( X_NOTHING );

    if( $token->[0] eq 'ID' ) {
        return $token;
    } elsif( $token->[0] eq 'OPBRK' ) {
        my $block = _parse_block( $self );

        return [ 'BLOCK', $block ];
    } elsif( $token->[0] eq 'DOLLAR' ) {
        my $indir = _parse_indirobj( $self );

        return [ 'SCALAR', $indir ];
    } else {
        die $token->[0], ' ', $token->[1];
    }
}

sub _parse_listop {
    my( $self ) = @_;
    my $op = $self->lexer->lex( X_NOTHING );
    my $token = $self->lexer->peek( X_TERM );
    my $args;

    if( $token->[0] eq 'OPPAR' ) {
        $self->lexer->lex; # comsume token
        $args = _parse_cslist( $self );
        my $cl = $self->lexer->lex( X_NOTHING );

        die $cl->[0], ' ', $cl->[1] unless $cl->[0] eq 'CLPAR';
    } else {
        $args = _parse_cslist( $self );
    }

    return Language::P::ParseTree::FunctionCall->new( { function  => $op->[1],
                                                        arguments => $args,
                                                        } );
}

sub _parse_cslist {
    my( $self ) = @_;

    my $term = _parse_term( $self );
    return _parse_cslist_rest( $self, $term );
}

sub _parse_cslist_rest {
    my( $self, @terms ) = @_;

    for(;;) {
        my $comma = $self->lexer->lex( X_TERM );
        if( $comma->[0] eq 'COMMA' ) {
            push @terms, scalar _parse_term( $self );
        } else {
            $self->lexer->unlex( $comma );
            last;
        }
    }

    return \@terms;
}

1;
