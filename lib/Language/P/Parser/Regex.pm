package Language::P::Parser::Regex;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Language::P::Lexer qw(:all);
use Language::P::ParseTree qw(:all);

__PACKAGE__->mk_ro_accessors( qw(lexer generator runtime
                                 interpolate) );

# will be used to parse embedded code blocks
sub parser { die; }

sub parse_string {
    my( $self, $string ) = @_;

    $self->{lexer} = Language::P::Lexer->new( { string => $string } );
    $self->_parse;
}

sub _parse {
    my( $self ) = @_;
    my( @values );

    $self->lexer->quote( { interpolate          => $self->interpolate,
                           pattern              => 1,
                           interpolated_pattern => 0,
                           } );

    my( $in_group, $st ) = ( 0, \@values );
    for(;;) {
        my $value = $self->lexer->lex_quote;

        if( $value->[0] == T_STRING ) {
            push @$st,
                Language::P::ParseTree::Constant->new( { flags => CONST_STRING,
                                                         value => $value->[1],
                                                         } );
        } elsif( $value->[0] == T_PATTERN ) {
            if( $value->[1] eq ')' ) {
                die 'Unmatched ) in regex' unless $in_group;

                --$in_group;
                $st = pop @values;
            } elsif( $value->[1] eq '(?' ) {
                ++$in_group;
                my $type = $self->lexer->lex_pattern_group;

                if( $type->[1] eq ':' ) {
                    push @$st, Language::P::ParseTree::RXGroup->new
                                   ( { components => [],
                                       capture    => 0,
                                       } );
                } else {
                    # remaining (?...) constructs
                    die "Unhandled (?$type->[1]) in regex";
                }

                my $nst = $st->[-1]->components;
                push @values, $st;
                $st = $nst;
            } elsif( $value->[1] eq '(' ) {
                ++$in_group;
                push @$st, Language::P::ParseTree::RXGroup->new
                               ( { components => [],
                                   capture    => 1,
                                   } );
                my $nst = $st->[-1]->components;
                push @values, $st;
                $st = $nst;
            } elsif( $value->[1] eq '|' ) {
                my $alt = Language::P::ParseTree::RXAlternation->new
                              ( { left  => [ @$st ],
                                  right => [],
                                  } );
                @$st = $alt;
                $st = $alt->right;
            } elsif( $value->[2]->[0] == T_QUANTIFIER ) {
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
                                    min    => $value->[2]->[1],
                                    max    => $value->[2]->[2],
                                    greedy => $value->[2]->[3],
                                    } );
            } elsif( $value->[2]->[0] == T_ASSERTION ) {
                push @$st, Language::P::ParseTree::RXAssertion->new
                               ( { type => $value->[2]->[1],
                                   } );
            } elsif( $value->[2]->[0] == T_CLASS ) {
                push @$st, Language::P::ParseTree::RXSpecialClass->new
                               ( { type => $value->[2]->[1],
                                   } );
            } elsif( $value->[2]->[0] == T_CLASS_START ) {
                push @$st, Language::P::ParseTree::RXClass->new
                               ( { elements => [],
                                   } );

                _parse_charclass( $self, $st->[-1] );
            } else {
                Carp::confess $value->[0], ' ', $value->[1], ' ',
                              $value->[2]->[0];
            }
        } elsif( $value->[0] == T_EOF ) {
            last;
        } elsif( $value->[0] == T_DOLLAR || $value->[0] == T_AT ) {
                Carp::confess $value->[0], ' ', $value->[1];
        }
    }

    die 'Unmatched ( in regex' if $in_group;

    return \@values;
}

sub _parse_charclass {
    my( $self, $class ) = @_;
    my $st = $class->elements;
    my @la;

    for(;;) {
        my $value = @la ? pop @la : $self->lexer->lex_charclass;
        last if $value->[0] == T_CLASS_END;
        if( $value->[0] == T_STRING ) {
            my $next = $self->lexer->lex_charclass;

            if( $next->[0] == T_MINUS ) {
                my $next_next = $self->lexer->lex_charclass;
                if( $next_next->[0] == T_STRING ) {
                    push @$st, Language::P::ParseTree::RXRange->new
                                   ( { start => $value->[1],
                                       end   => $next_next->[1],
                                       } );
                    next;
                } else {
                    push @la, $next_next, $next;
                }
            } else {
                push @la, $next;
            }
        } elsif( $value->[0] == T_CLASS ) {
            push @$st, Language::P::ParseTree::RXSpecialClass->new
                           ( { type => $value->[1],
                                } );
            next;
        }

        push @$st, $value->[1];
    }
}

1;
