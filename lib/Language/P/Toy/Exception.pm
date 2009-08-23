package Language::P::Toy::Exception;

use strict;
use warnings;
use base qw(Language::P::Exception);

__PACKAGE__->mk_accessors( qw(object) );

sub full_message {
    my( $self ) = @_;

    return $self->object ? $self->object->as_string : $self->format_message;
}

1;
