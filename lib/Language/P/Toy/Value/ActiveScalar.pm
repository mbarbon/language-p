package Language::P::Toy::Value::ActiveScalar;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Scalar);

sub _get {
    my( $self, $runtime ) = @_;

    Carp::confess "Implement active _get";
}

sub _set {
    my( $self, $runtime, $other ) = @_;

    Carp::confess "Implement active _set";
}

sub as_scalar {
    my( $self, $runtime ) = @_;

    return $self->_get( $runtime );
}

sub assign {
    my( $self, $runtime, $other ) = @_;

    $self->_set( $runtime, $other );
}

sub as_string {
    my( $self, $runtime ) = @_;

    return $self->_get->as_string( $runtime );
}

sub as_integer {
    my( $self, $runtime ) = @_;

    return $self->_get->as_integer( $runtime );
}

sub as_float {
    my( $self, $runtime ) = @_;

    return $self->_get->as_float( $runtime );
}

package Language::P::Toy::Value::ActiveScalarCallbacks;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::ActiveScalar);

__PACKAGE__->mk_ro_accessors( qw(get_callback set_callback) );

sub _get { $_[0]->get_callback->( $_[0], $_[1] ) }
sub _set { $_[0]->set_callback->( $_[0], $_[1], $_[2] ) }

1;
