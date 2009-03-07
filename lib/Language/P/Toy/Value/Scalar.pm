package Language::P::Toy::Value::Scalar;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

use Language::P::Toy::Value::Undef;

sub type { 5 }

sub new_boolean {
    my( $class, $value ) = @_;

    return $value ?
               Language::P::Toy::Value::StringNumber->new( { integer => 1 } ) :
               Language::P::Toy::Value::StringNumber->new( { string => '' } );
}

sub new_string {
    my( $class, $value ) = @_;

    return defined $value ?
               Language::P::Toy::Value::StringNumber->new( { string => $value } ) :
               Language::P::Toy::Value::Undef->new;
}

sub as_scalar { return $_[0] }

sub assign {
    my( $self, $other ) = @_;

    Carp::confess if ref( $other ) eq __PACKAGE__;

    # FIXME proper morphing
    %$self = ();
    bless $self, ref( $other );

    $self->assign( $other );
}

sub assign_iterator {
    my( $self, $iter ) = @_;

    die unless $iter->next; # FIXME, must assign undef
    $self->assign( $iter->item );
}

sub localize {
    my( $self ) = @_;

    return Language::P::Toy::Value::Undef->new;
}

1;
