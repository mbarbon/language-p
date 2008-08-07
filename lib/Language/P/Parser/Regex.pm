package Language::P::Parser::Regex;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Language::P::Lexer;
use Language::P::ParseTree;

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

    $self->lexer->quote( { interpolate => $self->interpolate,
                           pattern     => 1,
                           } );

    my( $in_group, $st ) = ( 0, \@values );
    for(;;) {
        my $value = $self->lexer->lex_quote;

        if( $value->[0] eq 'STRING' ) {
            push @$st,
                Language::P::ParseTree::Constant->new( { type  => 'string',
                                                         value => $value->[1],
                                                         } );
        } elsif( $value->[0] eq 'PATTERN' ) {
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
            } elsif( $value->[2]->[0] eq 'QUANTIFIER' ) {
                die 'Nothing to quantify in regex' unless @$st;

                if(    $st->[-1]->is_constant
                    && length( $st->[-1]->value ) > 1 ) {
                    my $last = chop $st->[-1]->{value}; # XXX

                    push @$st, Language::P::ParseTree::Constant->new
                                   ( { type  => 'string',
                                       value => $last,
                                       } );
                }

                $st->[-1] = Language::P::ParseTree::RXQuantifier->new
                                ( { node   => $st->[-1],
                                    min    => $value->[2]->[1],
                                    max    => $value->[2]->[2],
                                    greedy => $value->[2]->[3],
                                    } );
            } elsif( $value->[2]->[0] eq 'ASSERTION' ) {
                push @$st, Language::P::ParseTree::RXAssertion->new
                               ( { type => $value->[2]->[1],
                                   } );
            } elsif( $value->[2]->[0] eq 'CLASS' ) {
                push @$st, Language::P::ParseTree::RXClass->new
                               ( { elements => $value->[2]->[1],
                                   } );
            } else {
                Carp::confess $value->[0], ' ', $value->[1], ' ',
                              $value->[2]->[0];
            }
        } elsif( $value->[0] eq 'SPECIAL' ) {
            last;
        } elsif( $value->[0] eq 'DOLLAR' || $value->[0] eq 'AT' ) {
                Carp::confess $value->[0], ' ', $value->[1];
        }
    }

    die 'Unmatched ( in regex' if $in_group;

    return \@values;
}

1;
