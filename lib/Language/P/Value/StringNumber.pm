package Language::P::Value::StringNumber;

use strict;
use warnings;
use base qw(Language::P::Value::Scalar);

__PACKAGE__->mk_ro_accessors( qw(string integer) );

sub type { 11 }

sub clone {
    my( $self, $level ) = @_;

    return Language::P::Value::Scalar->new( { string  => $self->{string},
                                               integer => $self->{integer},
                                               } );
}

sub as_string {
    my( $self ) = @_;

    return $self->{string} if $self->{string};
    return sprintf "%d", $self->{integer} if $self->{integer};
    die;
}

sub as_integer {
    my( $self ) = @_;

    return $self->{integer};
}

sub assign {
    my( $self, $other ) = @_;

    die unless ref( $self ) eq ref( $other ); # FIXME morph

    $self->{string} = $other->{string};
    $self->{integer} = $other->{integer};
}

1;
