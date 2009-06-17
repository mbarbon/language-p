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

sub vivify_scalar {
    my( $self ) = @_;
    my $new = Language::P::Toy::Value::Reference->new
                  ( { reference => Language::P::Toy::Value::Undef->new,
                      } );
    $self->assign( $new );

    return $self->dereference_scalar;
}

sub vivify_array {
    my( $self ) = @_;
    my $new = Language::P::Toy::Value::Reference->new
                  ( { reference => Language::P::Toy::Value::Array->new,
                      } );
    $self->assign( $new );

    return $self->dereference_array;
}

sub vivify_hash {
    my( $self ) = @_;
    my $new = Language::P::Toy::Value::Reference->new
                  ( { reference => Language::P::Toy::Value::Hash->new,
                      } );
    $self->assign( $new );

    return $self->dereference_hash;
}

1;
