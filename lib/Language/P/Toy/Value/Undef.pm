package Language::P::Toy::Value::Undef;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Scalar);

sub type { 12 }

sub clone {
    my( $self, $level ) = @_;

    return Language::P::Toy::Value::Undef->new;
}

sub as_string {
    my( $self ) = @_;

    # FIXME warn
    return '';
}

sub as_integer {
    my( $self ) = @_;

    # FIXME warn
    return 0;
}

sub as_float {
    my( $self ) = @_;

    # FIXME warn
    return 0.0;
}

sub assign {
    my( $self, $other ) = @_;

    Language::P::Toy::Value::Scalar::assign( $self, $other )
        unless ref( $self ) eq ref( $other );

    # nothing to do
}

sub as_boolean_int {
    my( $self ) = @_;

    return 0;
}

sub is_defined {
    my( $self ) = @_;

    return 0;
}

1;
