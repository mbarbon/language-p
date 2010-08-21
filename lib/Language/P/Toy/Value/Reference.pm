package Language::P::Toy::Value::Reference;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Scalar);

__PACKAGE__->mk_ro_accessors( qw(reference) );

sub type { 10 }
sub is_overloaded { $_[0]->{reference}->is_overloaded_value }

sub clone {
    my( $self, $runtime, $level ) = @_;
    my $clone = Language::P::Toy::Value::Reference->new( $runtime, { reference => $self->{reference} } );

    $clone->{reference} = $clone->{reference}->clone( $runtime, $level - 1 )
      if $level > 0;

    return $clone;
}

sub assign {
    my( $self, $runtime, $other ) = @_;

    Language::P::Toy::Value::Scalar::assign( $self, $runtime, $other )
        unless ref( $self ) eq ref( $other );

    delete $self->{pos};
    $self->{reference} = $other->{reference};
}

sub dereference_scalar {
    my( $self, $runtime, $create ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Toy::Value::Scalar' );
    return $self->{reference};
}

sub vivify_scalar {
    my( $self, $runtime ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Toy::Value::Scalar' );
    return $self->{reference};
}

sub dereference_hash {
    my( $self, $runtime, $create ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Toy::Value::Hash' );
    return $self->{reference};
}

sub vivify_hash {
    my( $self, $runtime ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Toy::Value::Hash' );
    return $self->{reference};
}

sub dereference_array {
    my( $self, $runtime, $create ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Toy::Value::Array' );
    return $self->{reference};
}

sub vivify_array {
    my( $self, $runtime ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Toy::Value::Array' );
    return $self->{reference};
}

sub dereference_subroutine {
    my( $self, $runtime ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Toy::Value::Subroutine' );
    return $self->{reference};
}

sub dereference_glob {
    my( $self, $runtime, $create ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Toy::Value::Typeglob' );
    return $self->{reference};
}

sub as_string {
    my( $self, $runtime ) = @_;

    return sprintf '%s(0x%p)', _reference_string( $self ), $self->{reference};
}

sub as_integer {
    my( $self, $runtime ) = @_;

    return int( $self->{reference} );
}

sub as_boolean_int {
    my( $self, $runtime ) = @_;

    return 1;
}

sub _reference_string {
    my( $self ) = @_;
    my $ref = $self->{reference};

    if( $ref->is_blessed ) {
        return $ref->stash->name;
    }

    return $ref->isa( 'Language::P::Toy::Value::Reference' )  ? 'REF' :
           $ref->isa( 'Language::P::Toy::Value::Scalar' )     ? 'SCALAR' :
           $ref->isa( 'Language::P::Toy::Value::Hash' )       ? 'HASH' :
           $ref->isa( 'Language::P::Toy::Value::Array' )      ? 'ARRAY' :
           $ref->isa( 'Language::P::Toy::Value::Typeglob' )   ? 'GLOB' :
           $ref->isa( 'Language::P::Toy::Value::Subroutine' ) ? 'CODE' :
                                                                die "$ref";
}

sub reference_type {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::StringNumber->new
               ( $runtime,
                 { string => _reference_string( $self ),
                   } );
}

sub bless {
    my( $self, $runtime, $stash ) = @_;

    $self->reference->set_stash( $stash );
}

sub find_method {
    my( $self, $runtime, $name ) = @_;

    die "Value is not blessed" unless $self->reference->is_blessed;
    return $self->reference->stash->find_method( $runtime, $name );
}

sub as_handle {
    my( $self, $runtime ) = @_;
    my $glob = $self->dereference_glob( $runtime, 1 );

    return $glob->as_handle( $runtime );
}

sub set_handle {
    my( $self, $runtime, $handle ) = @_;
    my $glob = $self->dereference_glob( $runtime, 1 );

    $glob->set_handle( $runtime, $handle );
}

1;
