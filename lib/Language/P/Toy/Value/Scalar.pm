package Language::P::Toy::Value::Scalar;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Any);

use Language::P::Toy::Value::Undef;

sub type { 5 }

sub new_boolean {
    my( $class, $runtime, $value ) = @_;

    return $value ?
               Language::P::Toy::Value::StringNumber->new( $runtime, { integer => 1 } ) :
               Language::P::Toy::Value::StringNumber->new( $runtime, { string => '' } );
}

sub new_string {
    my( $class, $runtime, $value ) = @_;

    return defined $value ?
               Language::P::Toy::Value::StringNumber->new( $runtime, { string => $value } ) :
               Language::P::Toy::Value::Undef->new( $runtime );
}

sub as_scalar { return $_[0] }

sub assign {
    my( $self, $runtime, $other ) = @_;

    Carp::confess if ref( $other ) eq __PACKAGE__;

    # FIXME proper morphing
    %$self = ();
    bless $self, ref( $other );

    $self->assign( $runtime, $other );
}

sub assign_iterator {
    my( $self, $runtime, $iter ) = @_;

    die unless $iter->next; # FIXME, must assign undef
    $self->assign( $runtime, $iter->item );
}

sub localize {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Undef->new( $runtime );
}

sub reference_type {
    my( $self, $runtime ) = @_;

    return Language::P::Toy::Value::Scalar->new_boolean( $runtime, 0 );
}

sub find_method {
    my( $self, $runtime, $name ) = @_;
    my $stash = $runtime->symbol_table->get_package( $runtime, $self->as_string( $runtime ) );

    return undef unless $stash;
    return $stash->find_method( $runtime, $name );
}

# FIXME integer arithmetic, "aaa"++
sub pre_increment {
    my( $self, $runtime ) = @_;
    $self->assign( $runtime,
                   Language::P::Toy::Value::StringNumber->new
                       ( $runtime,
                         { float => $self->as_float( $runtime ) + 1,
                           } ) );

    return $self;
}

sub pre_decrement {
    my( $self, $runtime ) = @_;
    $self->assign( $runtime,
                   Language::P::Toy::Value::StringNumber->new
                       ( $runtime,
                         { float => $self->as_float( $runtime ) - 1,
                           } ) );

    return $self;
}

sub post_increment {
    my( $self, $runtime ) = @_;
    my $rv = $self->clone( $runtime, 0 );

    pre_increment( $self, $runtime );

    return $rv;
}

sub post_decrement {
    my( $self, $runtime ) = @_;
    my $rv = $self->clone( $runtime, 0 );

    pre_decrement( $self, $runtime );

    return $rv;
}

1;
