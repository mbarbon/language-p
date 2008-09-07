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

package Language::P::Toy::Value::Typeglob::Body;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(scalar array hash io format subroutine) );

use Language::P::Toy::Value::Scalar;
use Language::P::Toy::Value::Array;
# use Language::P::Toy::Value::Hash;
use Language::P::Toy::Value::Subroutine;
use Language::P::Toy::Value::Handle;
# use Language::P::Toy::Value::Format;

my %types =
  ( scalar     => 'Language::P::Toy::Value::Scalar',
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
