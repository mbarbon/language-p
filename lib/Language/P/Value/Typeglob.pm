package Language::P::Value::Typeglob;

use strict;
use warnings;
use base qw(Language::P::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(body) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{body} ||= Language::P::Value::Typeglob::Body->new;

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

package Language::P::Value::Typeglob::Body;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(scalar array hash io format subroutine) );

use Language::P::Value::Scalar;
use Language::P::Value::Array;
# use Language::P::Value::Hash;
use Language::P::Value::Subroutine;
use Language::P::Value::Handle;
# use Language::P::Value::Format;

my %types =
  ( scalar     => 'Language::P::Value::Scalar',
    array      => 'Language::P::Value::Array',
    hash       => 'Language::P::Value::Hash',
    subroutine => 'Language::P::Value::Subroutine',
    io         => 'Language::P::Value::Handle',
    format     => 'Language::P::Value::Format',
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
