package Language::P::Value::Reference;

use strict;
use warnings;
use base qw(Language::P::Value::Scalar);

__PACKAGE__->mk_ro_accessors( qw(reference) );

sub type { 10 }

sub clone {
    my( $self, $level ) = @_;
    my $clone = Language::P::Value::Reference->new( { reference => $self->{reference} } );

    $clone->{reference} = $clone->{reference}->clone( $level -1 )
      if $level > 0;

    return $clone;
}

sub assign {
    my( $self, $other ) = @_;

    die unless ref( $self ) eq ref( $other ); # FIXME morph

    $self->{reference} = $other->{reference};
}

sub dereference_scalar {
    my( $self ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Value::Scalar' );
    return $self->{reference};
}

sub dereference_hash {
    my( $self ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Value::Hash' );
    return $self->{reference};
}

sub dereference_array {
    my( $self ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Value::Array' );
    return $self->{reference};
}

sub dereference_subroutine {
    my( $self ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Value::Subroutine' );
    return $self->{reference};
}

sub dereference_typeglob {
    my( $self ) = @_;

    die unless $self->{reference}->isa( 'Language::P::Value::Typeglob' );
    return $self->{reference};
}

sub as_string {
    my( $self ) = @_;
    my $ref = $self->{reference};

    my $prefix = $ref->isa( 'Language::P::Value::Reference' ) ? 'REF' :
                 $ref->isa( 'Language::P::Value::Scalar' ) ? 'SCALAR' :
                 $ref->isa( 'Language::P::Value::Hash' ) ? 'HASH' :
                 $ref->isa( 'Language::P::Value::Array' ) ? 'ARRAY' :
                 $ref->isa( 'Language::P::Value::Typeglob' ) ? 'GLOB' :
                                                            die "$ref";

    return sprintf '%s(0x%p)', $prefix, $ref;
}

sub as_boolean_int {
    my( $self ) = @_;

    return 1;
}

1;
