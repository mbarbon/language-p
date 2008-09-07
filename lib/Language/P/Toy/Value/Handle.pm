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

1;
