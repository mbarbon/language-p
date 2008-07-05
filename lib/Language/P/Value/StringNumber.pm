package Language::P::Value::StringNumber;

use strict;
use warnings;
use base qw(Language::P::Value::Scalar);

__PACKAGE__->mk_ro_accessors( qw(string integer) );

sub type { 11 }

sub clone {
    my( $self, $level ) = @_;

    return Language::P::Value::StringNumber->new( { string  => $self->{string},
                                                    integer => $self->{integer},
                                                    } );
}

sub as_string {
    my( $self ) = @_;

    return $self->{string} if defined $self->{string};
    return sprintf "%d", $self->{integer} if defined $self->{integer};
    Carp::confess();
}

sub as_integer {
    my( $self ) = @_;

    return $self->{integer} if defined $self->{integer};
    return $self->{string} + 0 if defined $self->{string};
    return 0;
}

sub assign {
    my( $self, $other ) = @_;

    die unless ref( $self ) eq ref( $other ); # FIXME morph

    $self->{string} = $other->{string};
    $self->{integer} = $other->{integer};
}

sub as_boolean_int {
    my( $self ) = @_;

    if( defined $self->{integer} ) {
        return $self->{integer} != 0 ? 1 : 0;
    } elsif( defined $self->{string} ) {
        return length( $self->{string} ) && $self->{string} ne "0" ? 1 : 0;
    }

    die;
}

1;
