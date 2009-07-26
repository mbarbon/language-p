package Language::P::Exception;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(position message) );

sub throw {
    my( $class, %args ) = @_;

    die( $class->new( \%args ) );
}

sub full_message { $_[0]->message }

1;
