package Language::P::Toy::Value::ActiveScalar;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Scalar);

sub type { 14 }

sub _get {
    my( $self, $runtime ) = @_;

    Carp::confess( "Implement active _get" );
}

sub _set {
    my( $self, $runtime, $other ) = @_;

    Carp::confess( "Implement active _set" );
}

sub as_scalar {
    my( $self, $runtime ) = @_;

    return $self->_get( $runtime );
}

sub as_boolean_int {
    my( $self, $runtime ) = @_;

    return $self->_get( $runtime )->as_boolean_int( $runtime );
}

sub get_length_int {
    my( $self, $runtime ) = @_;

    return $self->_get( $runtime )->get_length_int( $runtime );
}

sub assign {
    my( $self, $runtime, $other ) = @_;

    $self->_set( $runtime, $other );
}

sub set_string {
    my( $self, $runtime, $other ) = @_;

    $self->_set_string( $runtime, $other );
}

sub set_integer {
    my( $self, $runtime, $other ) = @_;

    $self->_set_integer( $runtime, $other );
}

sub set_float {
    my( $self, $runtime, $other ) = @_;

    $self->_set_float( $runtime, $other );
}

sub get_pos {
    my( $self, $runtime ) = @_;

    return $self->_get( $runtime )->get_pos;
}

sub set_pos {
    my( $self, $runtime, $pos ) = @_;

    return $self->_get( $runtime )->set_pos( $runtime, $pos );
}

sub as_string {
    my( $self, $runtime ) = @_;

    return $self->_get( $runtime )->as_string( $runtime );
}

sub as_integer {
    my( $self, $runtime ) = @_;

    return $self->_get( $runtime )->as_integer( $runtime );
}

sub as_float {
    my( $self, $runtime ) = @_;

    return $self->_get( $runtime )->as_float( $runtime );
}

sub is_defined {
    my( $self, $runtime ) = @_;

    return $self->_get( $runtime )->is_defined( $runtime );
}

package Language::P::Toy::Value::ActiveScalarCallbacks;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::ActiveScalar);

__PACKAGE__->mk_ro_accessors( qw(get_callback set_callback) );

sub _get { $_[0]->get_callback->( $_[0], $_[1] ) }
sub _set { $_[0]->set_callback->( $_[0], $_[1], $_[2] ) }
sub _set_string  { $_[0]->set_callback->( $_[0], $_[1], Language::P::Toy::Value::Scalar->new_string( $_[1], $_[2] ) ) }
sub _set_integer { $_[0]->set_callback->( $_[0], $_[1], Language::P::Toy::Value::Scalar->new_integer( $_[1], $_[2] ) ) }
sub _set_float   { $_[0]->set_callback->( $_[0], $_[1], Language::P::Toy::Value::Scalar->new_float( $_[1], $_[2] ) ) }

1;
