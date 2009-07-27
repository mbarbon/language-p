package Language::P::Toy::Value::Typeglob;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(body) );

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{body} ||= Language::P::Toy::Value::Typeglob::Body->new( $runtime );

    return $self;
}

sub set_slot {
    my( $self, $runtime, $slot, $value ) = @_;

    $self->body->set_slot( $runtime, $slot, $value );
}

sub get_slot {
    my( $self, $runtime, $slot ) = @_;

    Carp::confess unless $slot;

    return $self->body->$slot;
}

sub get_or_create_slot {
    my( $self, $runtime, $slot ) = @_;

    return $self->body->get_or_create( $runtime, $slot );
}

sub as_boolean_int {
    my( $self, $runtime ) = @_;

    return 1;
}

sub dereference_scalar {
    my( $self, $runtime ) = @_;

    return $self->body->get_or_create( $runtime, 'scalar' );
}

sub vivify_scalar {
    my( $self, $runtime ) = @_;

    return $self->body->get_or_create( $runtime, 'scalar' );
}

sub dereference_array {
    my( $self, $runtime ) = @_;

    return $self->body->get_or_create( $runtime, 'array' );
}

sub vivify_array {
    my( $self, $runtime ) = @_;

    return $self->body->get_or_create( $runtime, 'array' );
}

sub dereference_hash {
    my( $self, $runtime ) = @_;

    return $self->body->get_or_create( $runtime, 'hash' );
}

sub vivify_hash {
    my( $self, $runtime ) = @_;

    return $self->body->get_or_create( $runtime, 'hash' );
}

sub assign {
    my( $self, $runtime, $other ) = @_;

    if( $other->isa( 'Language::P::Toy::Value::Reference' ) ) {
        my $ref = $other->reference;

        if( $ref->isa( 'Language::P::Toy::Value::Scalar' ) ) {
            $self->body->set_slot( $runtime, 'scalar', $ref );
        } elsif( $ref->isa( 'Language::P::Toy::Value::Array' ) ) {
            $self->body->set_slot( $runtime, 'array', $ref );
        } elsif( $ref->isa( 'Language::P::Toy::Value::Hash' ) ) {
            $self->body->set_slot( $runtime, 'hash', $ref );
        } elsif( $ref->isa( 'Language::P::Toy::Value::Code' ) ) {
            $self->body->set_slot( $runtime, 'subroutine', $ref );
        } elsif( $ref->isa( 'Language::P::Toy::Value::Typeglob' ) ) {
            $self->_assign_glob( $runtime, $other );
        } else {
            die 'Unhandled ', ref( $ref ), ' reference in glob assignment';
        }
    } elsif( $other->isa( 'Language::P::Toy::Value::Typeglob' ) ) {
        $self->_assign_glob( $runtime, $other );
    } else {
        die 'Unhandled ', ref( $other ), ' in glob assignment';
    }
}

sub _assign_glob {
    my( $self, $runtime, $other ) = @_;

    $self->{body} = $other->body;
}

package Language::P::Toy::Value::Typeglob::Body;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(scalar array hash io format subroutine) );

use Language::P::Toy::Value::Scalar;
use Language::P::Toy::Value::Array;
use Language::P::Toy::Value::Hash;
use Language::P::Toy::Value::Subroutine;
use Language::P::Toy::Value::Handle;
# use Language::P::Toy::Value::Format;

my %types =
  ( scalar     => 'Language::P::Toy::Value::Undef',
    array      => 'Language::P::Toy::Value::Array',
    hash       => 'Language::P::Toy::Value::Hash',
    subroutine => 'Language::P::Toy::Value::Subroutine',
    io         => 'Language::P::Toy::Value::Handle',
    format     => 'Language::P::Toy::Value::Format',
    );

sub set_slot {
    my( $self, $runtime, $slot, $value ) = @_;

    die unless $self->can( $slot );

    $self->{$slot} = $value;
}

sub get_or_create {
    my( $self, $runtime, $slot ) = @_;

    return $self->{$slot} ||= $types{$slot}->new( $runtime );
}

1;
