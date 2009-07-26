package Language::P::Parser::Exception;

use strict;
use warnings;
use base qw(Language::P::Exception);

sub full_message {
    my( $self ) = @_;

    return sprintf '%s at %s line %d', $self->{message},
                   $self->{position}[0], $self->{position}[1];
}

1;
