package Language::P::Toy::Value::Handle;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(handle) );

sub type { 4 }

sub as_handle {
    my( $self, $runtime ) = @_;

    return $self;
}

sub write {
    my( $self, $runtime, $scalar, $offset, $length ) = @_;
    local $\;

    my $buffer = $scalar->as_string( $runtime );
    if( defined $offset ) {
        print { $self->handle } defined( $length ) ?
                                    substr( $buffer, $offset, $length ) :
                                    substr( $buffer, $offset );
    } else {
        print { $self->handle } defined( $length ) ?
                                    substr( $buffer, 0, $length ) :
                                    $buffer;
    }
}

sub close {
    my( $self, $runtime ) = @_;
    my $ret = close $self->handle;

    return Language::P::Toy::Value::Scalar->new_boolean( $runtime, $ret );
}

sub read_line {
    my( $self, $runtime ) = @_;

    return scalar readline $self->handle;
}

sub read_lines {
    my( $self, $runtime ) = @_;

    return [ readline $self->handle ];
}

sub set_layer {
    my( $self, $runtime, $layer ) = @_;
    my $ret = binmode $self->handle, $layer;

    return Language::P::Toy::Value::Scalar->new_string( $runtime, $ret );
}

1;
