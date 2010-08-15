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

sub new_integer {
    my( $class, $runtime, $value ) = @_;

    return defined $value ?
               Language::P::Toy::Value::StringNumber->new( $runtime, { integer => $value } ) :
               Language::P::Toy::Value::Undef->new( $runtime );
}

sub new_float {
    my( $class, $runtime, $value ) = @_;

    return defined $value ?
               Language::P::Toy::Value::StringNumber->new( $runtime, { float => $value } ) :
               Language::P::Toy::Value::Undef->new( $runtime );
}

sub as_scalar { return $_[0] }
sub as_integer { return int( $_[0]->as_float( $_[1] ) ) }
sub as_float { return $_[0]->as_integer( $_[1] ) }

sub undefine {
    my( $self, $runtime ) = @_;

    %$self = ();
    bless $self, 'Language::P::Toy::Value::Undef';
}

sub assign {
    my( $self, $runtime, $other ) = @_;

    Carp::confess() if ref( $other ) eq __PACKAGE__;
    # avoid the need to special-case scalar context everywhere
    if(    (    !$other->isa( 'Language::P::Toy::Value::Scalar' )
             && !$other->isa( 'Language::P::Toy::Value::Typeglob' ) )
        || $other->isa( 'Language::P::Toy::Value::ActiveScalar' ) ) {
        assign( $self, $runtime, $other->as_scalar );
        return;
    }

    # FIXME proper morphing
    %$self = ();
    bless $self, ref( $other );

    $self->assign( $runtime, $other );
}

sub assign_iterator {
    my( $self, $runtime, $iter ) = @_;

    if( $iter && $iter->next ) {
        $self->assign( $runtime, $iter->item );

        return 1;
    } else {
        $self->assign( $runtime,
                       Language::P::Toy::Value::Undef->new( $runtime ) );

        return 0;
    }
}

sub set_pos { $_[0]->{pos} = $_[2] }
sub get_pos { $_[0]->{pos} }

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

    $stash ||= $runtime->symbol_table->get_package( $runtime, 'UNIVERSAL' );
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

sub get_length_int {
    my( $self, $runtime ) = @_;

    return length( $self->as_string( $runtime ) );
}

1;
