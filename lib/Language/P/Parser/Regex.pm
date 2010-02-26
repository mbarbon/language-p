package Language::P::Parser::Regex;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Language::P::Lexer qw(:all);
use Language::P::ParseTree qw(:all);

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

sub _parse {
    my( $self ) = @_;

    $self->lexer->quote( { interpolate          => $self->interpolate,
                           pattern              => 1,
                           interpolated_pattern => 0,
                           } );

    my( @values );
    my( $in_group, $st, $flags ) = ( 0, \@values, $self->flags );
    for(;;) {
        my $value = $self->lexer->lex_quote;

        if( $value->[O_TYPE] == T_STRING ) {
            push @$st, Language::P::ParseTree::Constant->new
                           ( { flags => CONST_STRING,
                               value => $value->[O_VALUE],
                               } );
        } elsif( $value->[O_TYPE] == T_PATTERN ) {
            if( $value->[O_VALUE] eq ')' ) {
                die 'Unmatched ) in regex' unless $in_group;

                --$in_group;
                $st = pop @values;
            } elsif( $value->[O_VALUE] eq '(?' ) {
                ++$in_group;
                my $type = $self->lexer->lex_pattern_group;

                if( $type->[O_VALUE] eq ':' ) {
                    push @$st, Language::P::ParseTree::RXGroup->new
                                   ( { components => [],
                                       capture    => 0,
                                       } );
                } else {
                    # remaining (?...) constructs
                    die "Unhandled (?" . $type->[O_VALUE] . ") in regex";
                }

                my $nst = $st->[-1]->components;
                push @values, $st;
                $st = $nst;
            } elsif( $value->[O_VALUE] eq '(' ) {
                ++$in_group;
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

                if(    $st->[-1]->is_constant
                    && length( $st->[-1]->value ) > 1 ) {
                    my $last = chop $st->[-1]->{value}; # XXX

                    push @$st, Language::P::ParseTree::Constant->new
                                   ( { flags => CONST_STRING,
                                       value => $last,
                                       } );
                }

                $st->[-1] = Language::P::ParseTree::RXQuantifier->new
                                ( { node   => $st->[-1],
                                    min    => $value->[O_RX_REST]->[1],
                                    max    => $value->[O_RX_REST]->[2],
                                    greedy => $value->[O_RX_REST]->[3],
                                    } );
            } elsif( $value->[O_RX_REST]->[0] == T_ASSERTION ) {
                my $assertion = $value->[O_RX_REST]->[1];

                if( $assertion eq 'ANY_SPECIAL' ) {
                    $assertion =
                      ( $flags & FLAG_RX_SINGLE_LINE ) ? 'ANY' :
                                                         'ANY_NONEWLINE';
                } elsif( $assertion eq 'START_SPECIAL' ) {
                    $assertion =
                      ( $flags & FLAG_RX_MULTI_LINE ) ? 'LINE_BEGINNING' :
                                                        'BEGINNING';
                } elsif( $assertion eq 'END_SPECIAL' ) {
                    $assertion =
                      ( $flags & FLAG_RX_MULTI_LINE ) ? 'LINE_END' :
                                                        'END_OR_NEWLINE';
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
                               ( { elements => [],
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
                    push @$st, Language::P::ParseTree::Constant->new
                                   ( { flags => CONST_STRING,
                                       value => chr oct '0' . $digits,
                                       } );
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

my %posix_charclasses = map { $_ => 1 } qw(alpha alnum ascii blank cntrl digit
                                           graph lower print punct space upper
                                           word xdigit);

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
                           ( { type => $value->[O_VALUE],
                                } );
            next;
        } elsif( $value->[O_TYPE] == T_CLASS ) {
            push @$st, Language::P::ParseTree::RXSpecialClass->new
                           ( { type => $value->[O_VALUE],
                                } );
            next;
        }

        push @$st, $value->[O_VALUE];
    }
}

1;
