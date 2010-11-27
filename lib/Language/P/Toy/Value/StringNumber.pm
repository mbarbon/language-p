package Language::P::Toy::Value::StringNumber;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Scalar);

__PACKAGE__->mk_ro_accessors( qw(string integer float) );

sub type { 11 }

sub clone {
    my( $self, $runtime, $level ) = @_;

    return Language::P::Toy::Value::StringNumber->new
               ( $runtime,
                 { string  => $self->{string},
                   integer => $self->{integer},
                   float   => $self->{float},
                   } );
}

sub is_string { defined $_[0]->{string} }
sub is_float { defined $_[0]->{float} }
sub is_integer { defined $_[0]->{integer} }

sub as_string {
    my( $self, $runtime ) = @_;

    return $self->{string} if defined $self->{string};
    return sprintf "%d", $self->{integer} if defined $self->{integer};
    return sprintf "%.15g", $self->{float} if defined $self->{float};
    Carp::confess( "StringNumber must have one slot set" );
}

sub as_integer {
    my( $self, $runtime ) = @_;

    return $self->{integer} if defined $self->{integer};
    return int( $self->{float} ) if defined $self->{float};
    return $self->{string} + 0 if defined $self->{string};
    Carp::confess( "StringNumber must have one slot set" );
}

sub as_float {
    my( $self, $runtime ) = @_;

    return $self->{float} if defined $self->{float};
    return $self->{integer} if defined $self->{integer};
    return $self->{string} + 0.0 if defined $self->{string};
    Carp::confess( "StringNumber must have one slot set" );
}

sub assign {
    my( $self, $runtime, $other ) = @_;

    return Language::P::Toy::Value::Scalar::assign( $self, $runtime, $other )
        unless ref( $self ) eq ref( $other );

    $self->{string} = $other->{string};
    $self->{integer} = $other->{integer};
    $self->{float} = $other->{float};
}

sub set_string { delete $_[0]->{pos}; $_[0]->{string} = $_[2] }
sub set_integer { delete $_[0]->{pos}; $_[0]->{integer} = $_[2] }
sub set_float { delete $_[0]->{pos}; $_[0]->{float} = $_[2] }

sub as_boolean_int {
    my( $self, $runtime ) = @_;

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
    my( $self, $runtime ) = @_;

    return 1;
}

sub get_length_int {
    my( $self, $runtime ) = @_;

    if( defined $self->{string} ) {
        return length $self->{string};
    } else {
        return length $self->as_string( $runtime );
    }
}

1;
