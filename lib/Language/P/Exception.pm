package Language::P::Exception;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(position message) );

sub throw {
    my( $class, %args ) = @_;

    die( $class->new( \%args ) );
}

sub full_message { $_[0]->message }

sub format_message {
    my( $self ) = @_;

    return $self->{message} if $self->{message} =~ /\n$/;
    return sprintf "%s at %s line %d.\n", $self->{message},
                   $self->{position}[0], $self->{position}[1];

}

1;
