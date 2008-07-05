package Language::P::Value::Array;

use strict;
use warnings;
use base qw(Language::P::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(array) );

sub type { 2 }

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{array} ||= [];

    return $self;
}

sub clone {
    my( $self, $level ) = @_;

    return Language::P::Value::Array->new( { array  => $self->{array},
                                              } );
}

sub push {
    my( $self, @values ) = @_;

    push @{$self->{array}}, @values;

    return;
}

sub iterator {
    my( $self ) = @_;

    return Language::P::Value::Array::Iterator->new( $self );
}

sub iterator_from {
    my( $self, $index ) = @_;

    return Language::P::Value::Array::Iterator->new( $self, $index );
}

sub get_item {
    my( $self, $index ) = @_;

    die 'Array index out of range'
        if $index < 0 || $index > $#{$self->{array}};

    return $self->{array}->[$index];
}

sub get_count {
    my( $self ) = @_;

    return scalar @{$self->{array}};
}

sub as_scalar {
    my( $self ) = @_;

    return Language::P::Value::StringNumber->new( { integer => $self->get_count } );
}

sub as_boolean_int {
    my( $self ) = @_;

    return $self->get_count ? 1 : 0;
}

package Language::P::Value::Array::Iterator;

use strict;
use warnings;
use base qw(Language::P::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(array index) );

sub type { 3 }

sub new {
    my( $class, $array, $index ) = @_;
    my $self = $class->SUPER::new( { array => $array,
                                     index => ( $index || 0 ) - 1,
                                     } );
}

sub next {
    my( $self ) = @_;
    return 0 if $self->{index} >= $self->{array}->get_count - 1;

    ++$self->{index};

    return 1;
}

sub item {
    my( $self ) = @_;

    return $self->{array}->get_item( $self->{index} );
}

1;
