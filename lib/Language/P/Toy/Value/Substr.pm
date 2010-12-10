package Language::P::Toy::Value::Substr;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::ActiveScalar);

__PACKAGE__->mk_ro_accessors( qw(value offset length) );

sub new {
    my( $class, $runtime, $scalar, $offset, $length ) = @_;

    return $class->SUPER::new( $runtime,
                               { value   => $scalar,
                                 offset  => $offset,
                                 length  => $length,
                                 } );
}

sub is_string { 1 }

sub _get {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Scalar->new_string
               ( $runtime, substr( $self->value->as_string( $runtime ),
                                   $self->offset, $self->length ) );
}

sub _set {
    my( $self, $runtime, $value ) = @_;
    my $str = $self->value->as_string( $runtime );
    substr $str, $self->offset, $self->length, $value->as_string( $runtime );
    my $new = Language::P::Toy::Value::Scalar->new_string( $runtime, $str );

    $self->value->assign( $runtime, $new );
}

1;
