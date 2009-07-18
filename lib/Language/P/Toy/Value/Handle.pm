package Language::P::Toy::Value::Handle;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(handle) );

sub type { 4 }

sub write {
    my( $self, $scalar, $offset, $length ) = @_;
    local $\;

    my $buffer = $scalar->as_string;
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
    my( $self ) = @_;
    my $ret = close $self->handle;

    return Language::P::Toy::Value::Scalar->new_boolean( $ret );
}

sub read_line {
    my( $self ) = @_;

    return scalar readline $self->handle;
}

sub read_lines {
    my( $self ) = @_;

    return [ readline $self->handle ];
}

sub set_layer {
    my( $self, $layer ) = @_;
    my $ret = binmode $self->handle, $layer;

    return Language::P::Toy::Scalar->new_string( $ret );
}

1;
