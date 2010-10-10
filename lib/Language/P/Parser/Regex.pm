package Language::P::Parser::Regex;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Language::P::Constants qw(:all);
use Language::P::Lexer qw(:all);
use Language::P::ParseTree;

__PACKAGE__->mk_ro_accessors( qw(lexer generator runtime
                                 interpolate flags _group_count) );

# will be used to parse embedded code blocks
sub parser { die; }

sub parse_string {
    my( $self, $string ) = @_;

    $self->{lexer} = Language::P::Lexer->new( { string => $string } );
    $self->{_group_count} = 0;
    $self->_parse;
}

sub _flag_letters {
    my( $flags ) = @_;
    my $chars = '';

    $chars .= 'x' if $flags & FLAG_RX_FREE_FORMAT;
    $chars .= 'i' if $flags & FLAG_RX_CASE_INSENSITIVE;
    $chars .= 's' if $flags & FLAG_RX_SINGLE_LINE;
    $chars .= 'm' if $flags & FLAG_RX_MULTI_LINE;

    return $chars;
}

sub _parse_flags {
    my( $flags ) = @_;
    my $value = 0;

    for my $i ( 0 .. length( $flags ) - 1 ) {
        my $c = substr $flags, $i, 1;

        if( $c eq 'x' ) {
            $value |= FLAG_RX_FREE_FORMAT;
        } elsif( $c eq 'i' ) {
            $value |= FLAG_RX_CASE_INSENSITIVE;
        } elsif( $c eq 's' ) {
            $value |= FLAG_RX_SINGLE_LINE;
        } elsif( $c eq 'm' ) {
            $value |= FLAG_RX_MULTI_LINE;
        } else {
            return -1;
        }
    }

    return $value;
}

sub quote_original {
    my( $class, $string, $flags ) = @_;
    my $remove = FLAG_RX_QR_ALL & ~$flags;

    return sprintf "(?%s-%s:%s)", _flag_letters( $flags ),
                                  _flag_letters( $remove ),
                                  $$string;
}

sub _constant {
    my( $string, $flags ) = @_;

    return Language::P::ParseTree::RXConstant->new
               ( { value       => $string,
                   insensitive => $flags & FLAG_RX_CASE_INSENSITIVE,
                   } );
}

sub _parse {
    my( $self ) = @_;

    $self->lexer->quote( { interpolate          => $self->interpolate,
                           pattern              => 1,
                           interpolated_pattern => 0,
                           } );

    my( @values );
    my( $in_group, $st, $flags ) = ( 0, \@values, $self->flags );
    my @flags = ( $self->flags );
    for(;;) {
        my $value = $self->lexer->lex_quote;

        if( $value->[O_TYPE] == T_STRING ) {
            push @$st, _constant( $value->[O_VALUE], $flags );
        } elsif( $value->[O_TYPE] == T_PATTERN ) {
            if( $value->[O_VALUE] eq ')' ) {
                die 'Unmatched ) in regex' unless $in_group;

                --$in_group;
                $st = pop @values;
                $flags = pop @flags;
            } elsif( $value->[O_VALUE] eq '(?' ) {
                my $is_group = 1;
                my $type = $self->lexer->lex_pattern_group;

                if( $type->[O_VALUE] eq ':' ) {
                    push @$st, Language::P::ParseTree::RXGroup->new
                                   ( { components => [],
                                       capture    => 0,
                                       } );
                } elsif( $type->[O_VALUE] eq '=' ) {
                    push @$st, Language::P::ParseTree::RXAssertionGroup->new
                                   ( { components => [],
                                       type       => RX_GROUP_POSITIVE_LOOKAHEAD,
                                       } );
                } elsif( $type->[O_VALUE] eq '!' ) {
                    push @$st, Language::P::ParseTree::RXAssertionGroup->new
                                   ( { components => [],
                                       type       => RX_GROUP_NEGATIVE_LOOKAHEAD,
                                       } );
                } elsif( $type->[O_VALUE] eq '<=' ) {
                    push @$st, Language::P::ParseTree::RXAssertionGroup->new
                                   ( { components => [],
                                       type       => RX_GROUP_POSITIVE_LOOKBEHIND,
                                       } );
                } elsif( $type->[O_VALUE] eq '<!' ) {
                    push @$st, Language::P::ParseTree::RXAssertionGroup->new
                                   ( { components => [],
                                       type       => RX_GROUP_NEGATIVE_LOOKBEHIND,
                                       } );
                } elsif( $type->[O_VALUE] =~ /([a-z]*)-([a-z]*)(:?)/ ) {
                    my( $add, $rem, $colon ) = ( $1, $2, $3 );
                    my $add_flags = _parse_flags( $add );
                    my $rem_flags = _parse_flags( $rem );

                    if( $add_flags == -1 ) {
                        Language::P::Parser::Exception->throw
                            ( message  => sprintf( "Sequence (?%s...) not recognized in regex",
                                                   $add ),
                              position => $value->[O_POS],
                              );
                    } elsif( $rem_flags == -1 ) {
                        Language::P::Parser::Exception->throw
                            ( message  => sprintf( "Sequence (?%s-%s...) not recognized in regex",
                                                   $add, $rem ),
                              position => $value->[O_POS],
                              );
                    } else {
                        $flags = ( $flags | $add_flags ) & ~$rem_flags;
                    }

                    if( $colon ) {
                        push @$st, Language::P::ParseTree::RXGroup->new
                                       ( { components => [],
                                           capture    => 0,
                                           } );
                    } else {
                        my $paren = $self->lexer->lex_quote;

                        if( $paren->[O_VALUE] ne ')' ) {
                            Language::P::Parser::Exception->throw
                                ( message  => sprintf( "Sequence (?%s-%s%s...) not recognized in regex",
                                                       $add, $rem, $paren->[O_VALUE] ),
                                  position => $value->[O_POS],
                                  );
                        }

                        $is_group = 0;
                    }
                } else {
                    # remaining (?...) constructs
                    die "Unhandled (?" . $type->[O_VALUE] . ") in regex";
                }

                if( $is_group ) {
                    ++$in_group;
                    push @flags, $flags;

                    my $nst = $st->[-1]->components;
                    push @values, $st;
                    $st = $nst;
                }
            } elsif( $value->[O_VALUE] eq '(' ) {
                ++$in_group;
                push @flags, $flags;
                ++$self->{_group_count};
                push @$st, Language::P::ParseTree::RXGroup->new
                               ( { components => [],
                                   capture    => 1,
                                   } );
                my $nst = $st->[-1]->components;
                push @values, $st;
                $st = $nst;
            } elsif( $value->[O_VALUE] eq '|' ) {
                my $alt = Language::P::ParseTree::RXAlternation->new
                              ( { left  => [ @$st ],
                                  right => [],
                                  } );
                @$st = $alt;
                $st = $alt->right;
            } elsif( $value->[O_RX_REST]->[0] == T_QUANTIFIER ) {
                die 'Nothing to quantify in regex' unless @$st;

                if(    $st->[-1]->isa( 'Language::P::ParseTree::RXConstant' )
                    && length( $st->[-1]->value ) > 1 ) {
                    my $last = chop $st->[-1]->{value}; # XXX

                    push @$st, _constant( $last, $flags );
                }

                $st->[-1] = Language::P::ParseTree::RXQuantifier->new
                                ( { node   => $st->[-1],
                                    min    => $value->[O_RX_REST]->[1],
                                    max    => $value->[O_RX_REST]->[2],
                                    greedy => $value->[O_RX_REST]->[3],
                                    } );
            } elsif( $value->[O_RX_REST]->[0] == T_ASSERTION ) {
                my $assertion = $value->[O_RX_REST]->[1];

                if( $assertion == RX_ASSERTION_ANY_SPECIAL ) {
                    $assertion =
                      ( $flags & FLAG_RX_SINGLE_LINE ) ? RX_ASSERTION_ANY :
                                                         RX_ASSERTION_ANY_NONEWLINE;
                } elsif( $assertion == RX_ASSERTION_START_SPECIAL ) {
                    $assertion =
                      ( $flags & FLAG_RX_MULTI_LINE ) ? RX_ASSERTION_LINE_BEGINNING :
                                                        RX_ASSERTION_BEGINNING;
                } elsif( $assertion == RX_ASSERTION_END_SPECIAL ) {
                    $assertion =
                      ( $flags & FLAG_RX_MULTI_LINE ) ? RX_ASSERTION_LINE_END :
                                                        RX_ASSERTION_END_OR_NEWLINE;
                }

                push @$st, Language::P::ParseTree::RXAssertion->new
                               ( { type => $assertion,
                                   } );
            } elsif( $value->[O_RX_REST]->[0] == T_CLASS ) {
                push @$st, Language::P::ParseTree::RXSpecialClass->new
                               ( { type => $value->[O_RX_REST]->[1],
                                   } );
            } elsif( $value->[O_RX_REST]->[0] == T_CLASS_START ) {
                push @$st, Language::P::ParseTree::RXClass->new
                               ( { elements    => [],
                                   insensitive => $flags & FLAG_RX_CASE_INSENSITIVE,
                                   } );

                _parse_charclass( $self, $st->[-1] );
            } elsif( $value->[O_RX_REST]->[0] == T_BACKREFERENCE ) {
                my $idx = $value->[O_RX_REST]->[1];

                if( $idx < 10 || $idx <= $self->_group_count ) {
                    push @$st, Language::P::ParseTree::RXBackreference->new
                                   ( { group => $idx,,
                                       } );
                } else {
                    my $digits = $value->[O_VALUE];

                    $digits =~ /^[89]/ and die "Invalid octal digit";
                    push @$st, _constant( chr( oct '0' . $digits ), $flags );
                }
            } else {
                Carp::confess( $value->[O_TYPE], ' ', $value->[O_VALUE], ' ',
                               $value->[O_RX_REST]->[0] );
            }
        } elsif( $value->[O_TYPE] == T_EOF ) {
            last;
        } elsif( $value->[O_TYPE] == T_DOLLAR || $value->[O_TYPE] == T_AT ) {
                Carp::confess( $value->[O_TYPE], ' ', $value->[O_VALUE] );
        }
    }

    die 'Unmatched ( in regex' if $in_group;

    return \@values;
}

my %posix_charclasses =
  ( alpha  => RX_POSIX_ALPHA,
    alnum  => RX_POSIX_ALNUM,
    ascii  => RX_POSIX_ASCII,
    blank  => RX_POSIX_BLANK,
    cntrl  => RX_POSIX_CNTRL,
    digit  => RX_POSIX_DIGIT,
    graph  => RX_POSIX_GRAPH,
    lower  => RX_POSIX_LOWER,
    print  => RX_POSIX_PRINT,
    punct  => RX_POSIX_PUNCT,
    space  => RX_POSIX_SPACE,
    upper  => RX_POSIX_UPPER,
    word   => RX_POSIX_WORD,
    xdigit => RX_POSIX_XDIGIT,
    );

sub _parse_charclass {
    my( $self, $class ) = @_;
    my $st = $class->elements;
    my @la;

    for(;;) {
        my $value = @la ? pop @la : $self->lexer->lex_charclass;
        last if $value->[O_TYPE] == T_CLASS_END;
        if( $value->[O_TYPE] == T_STRING ) {
            my $next = $self->lexer->lex_charclass;

            if( $next->[O_TYPE] == T_MINUS ) {
                my $next_next = $self->lexer->lex_charclass;
                if( $next_next->[O_TYPE] == T_STRING ) {
                    push @$st, Language::P::ParseTree::RXRange->new
                                   ( { start => $value->[O_VALUE],
                                       end   => $next_next->[O_VALUE],
                                       } );
                    next;
                } else {
                    push @la, $next_next, $next;
                }
            } else {
                push @la, $next;
            }
        } elsif( $value->[O_TYPE] == T_POSIX ) {
            if( !$posix_charclasses{$value->[O_VALUE]} ) {
                throw Language::P::Parser::Exception
                  ( message  => sprintf( "Invalid POSIX character class '%s'",
                                         $value->[O_VALUE] ),
                    position => $value->[O_POS],
                    );
            }

            push @$st, Language::P::ParseTree::RXPosixClass->new
                           ( { type => $posix_charclasses{$value->[O_VALUE]},
                                } );
            next;
        } elsif( $value->[O_TYPE] == T_CLASS ) {
            push @$st, Language::P::ParseTree::RXSpecialClass->new
                           ( { type => $value->[O_VALUE],
                                } );
            next;
        }

        push @$st, Language::P::ParseTree::Constant->new
                       ( { flags => CONST_STRING,
                           value => $value->[O_VALUE],
                           } );
    }
}

1;
