package Language::P::Toy::Value::ActiveScalar;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Scalar);

sub _get {
    my( $self ) = @_;

    Carp::confess "Implement active _get";
}

sub _set {
    my( $self, $other ) = @_;

    Carp::confess "Implement active _set";
}

sub as_scalar {
    my( $self ) = @_;

    return $self->_get;
}

sub assign {
    my( $self, $other ) = @_;

    $self->_set( $other );
}

sub as_string {
    my( $self ) = @_;

    return $self->_get->as_string;
}

sub as_integer {
    my( $self ) = @_;

    return $self->_get->as_integer;
}

sub as_float {
    my( $self ) = @_;

    return $self->_get->as_float;
}

package Language::P::Toy::Value::ActiveScalarCallbacks;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::ActiveScalar);

__PACKAGE__->mk_ro_accessors( qw(get_callback set_callback) );

sub _get { $_[0]->get_callback->( $_[0] ) }
sub _set { $_[0]->set_callback->( $_[0], $_[1] ) }

1;
