package Language::P::Toy::Value::StringNumber;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Scalar);

__PACKAGE__->mk_ro_accessors( qw(string integer float) );

sub type { 11 }

sub clone {
    my( $self, $level ) = @_;

    return Language::P::Toy::Value::StringNumber->new( { string  => $self->{string},
                                                    integer => $self->{integer},
                                                    float   => $self->{float},
                                                    } );
}

sub as_string {
    my( $self ) = @_;

    return $self->{string} if defined $self->{string};
    return sprintf "%d", $self->{integer} if defined $self->{integer};
    return sprintf "%.15g", $self->{float} if defined $self->{float};
    Carp::confess( "StringNumber must have one slot set" );
}

sub as_integer {
    my( $self ) = @_;

    return $self->{integer} if defined $self->{integer};
    return int( $self->{float} ) if defined $self->{float};
    return $self->{string} + 0 if defined $self->{string};
    Carp::confess( "StringNumber must have one slot set" );
}

sub as_float {
    my( $self ) = @_;

    return $self->{float} if defined $self->{float};
    return $self->{integer} if defined $self->{integer};
    return $self->{string} + 0.0 if defined $self->{string};
    Carp::confess( "StringNumber must have one slot set" );
}

sub assign {
    my( $self, $other ) = @_;

    Language::P::Toy::Value::Scalar::assign( $self, $other )
        unless ref( $self ) eq ref( $other );

    $self->{string} = $other->{string};
    $self->{integer} = $other->{integer};
    $self->{float} = $other->{float};
}

sub as_boolean_int {
    my( $self ) = @_;

    if( defined $self->{integer} ) {
        return $self->{integer} != 0 ? 1 : 0;
    } elsif( defined $self->{float} ) {
        return $self->{float} != 0 ? 1 : 0;
    } elsif( defined $self->{string} ) {
        return length( $self->{string} ) && $self->{string} ne "0" ? 1 : 0;
    }

    Carp::confess( "StringNumber must have one slot set" );
}

sub is_defined {
    my( $self ) = @_;

    return 1;
}

1;
