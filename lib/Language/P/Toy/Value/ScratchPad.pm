package Language::P::Toy::Value::ScratchPad;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

use Language::P::Toy::Value::StringNumber;

__PACKAGE__->mk_ro_accessors( qw(outer names values) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{values} ||= [];
    $self->{names} ||= {};

    return $self;
}

sub new_scope {
    my( $self, $outer_scope ) = @_;

    # FIXME lexical initialization
    my @values = map { Language::P::Toy::Value::StringNumber->new }
                     0 .. $#{$self->values};
    return ref( $self )->new( { outer  => $outer_scope,
                                values => \@values,
                                } );
}

sub add_value {
    my( $self, $sigil ) = @_;

    # FIXME lexical initialization
    push @{$self->values}, Language::P::Toy::Value::StringNumber->new;

    return $#{$self->values};
}

1;
