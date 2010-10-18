package Language::P::Toy::Value::Vec;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::ActiveScalar);

__PACKAGE__->mk_ro_accessors( qw(value offset bits) );

sub new {
    my( $class, $runtime, $scalar, $offset, $bits ) = @_;

    return $class->SUPER::new( $runtime,
                               { value   => $scalar,
                                 offset  => $offset,
                                 bits    => $bits,
                                 } );
}

sub is_string { 1 }

sub _get {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Scalar->new_integer
               ( $runtime, vec( $self->value->as_string( $runtime ),
                                $self->offset, $self->bits ) );
}

sub _set {
    my( $self, $runtime, $value ) = @_;
    my $str = $self->value->as_string( $runtime );
    vec( $str, $self->offset, $self->bits ) = $value->as_integer( $runtime );
    my $new = Language::P::Toy::Value::Scalar->new_string( $runtime, $str );

    $self->value->assign( $runtime, $new );
}

1;
