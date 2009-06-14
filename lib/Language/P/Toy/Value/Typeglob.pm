package Language::P::Toy::Value::Typeglob;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(body) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{body} ||= Language::P::Toy::Value::Typeglob::Body->new;

    return $self;
}

sub set_slot {
    my( $self, $slot, $value ) = @_;

    $self->body->set_slot( $slot, $value );
}

sub get_slot {
    my( $self, $slot ) = @_;

    Carp::confess unless $slot;

    return $self->body->$slot;
}

sub get_or_create_slot {
    my( $self, $slot ) = @_;

    return $self->body->get_or_create( $slot );
}

sub as_boolean_int {
    my( $self ) = @_;

    return 1;
}

sub dereference_scalar {
    my( $self ) = @_;

    return $self->body->scalar || Language::P::Toy::Value::Undef->new;
}

sub dereference_array {
    my( $self ) = @_;

    return $self->body->array || Language::P::Toy::Value::Undef->new;
}

sub dereference_hash {
    my( $self ) = @_;

    return $self->body->hash || Language::P::Toy::Value::Undef->new;
}

sub assign {
    my( $self, $other ) = @_;

    if( $other->isa( 'Language::P::Toy::Value::Reference' ) ) {
        my $ref = $other->reference;

        if( $ref->isa( 'Language::P::Toy::Value::Scalar' ) ) {
            $self->body->set_slot( 'scalar', $ref );
        } elsif( $ref->isa( 'Language::P::Toy::Value::Array' ) ) {
            $self->body->set_slot( 'array', $ref );
        } elsif( $ref->isa( 'Language::P::Toy::Value::Hash' ) ) {
            $self->body->set_slot( 'hash', $ref );
        } elsif( $ref->isa( 'Language::P::Toy::Value::Code' ) ) {
            $self->body->set_slot( 'subroutine', $ref );
        } elsif( $ref->isa( 'Language::P::Toy::Value::Typeglob' ) ) {
            $self->_assign_glob( $other );
        } else {
            die 'Unhandled ', ref( $ref ), ' reference in glob assignment';
        }
    } elsif( $other->isa( 'Language::P::Toy::Value::Typeglob' ) ) {
        $self->_assign_glob( $other );
    } else {
        die 'Unhandled ', ref( $other ), ' in glob assignment';
    }
}

sub _assign_glob {
    my( $self, $other ) = @_;

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
    my( $self, $slot, $value ) = @_;

    die unless $self->can( $slot );

    $self->{$slot} = $value;
}

sub get_or_create {
    my( $self, $slot ) = @_;

    return $self->{$slot} ||= $types{$slot}->new;
}

1;
