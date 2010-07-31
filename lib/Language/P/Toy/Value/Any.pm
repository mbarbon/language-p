package Language::P::Toy::Value::Any;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(stash) );

use Carp;

our @METHODS = qw(as_integer as_float as_string as_scalar as_boolean_int
                  as_handle undefine
                  set_integer set_float set_string set_handle
                  localize pre_increment post_increment pre_decrement
                  post_decrement

                  get_item iterator iterator_from push_value get_count
                  push_list pop_value unshift_list shift_value slice

                  call find_method

                  reference_type bless

                  set_layer

                  get_pos set_pos
                  );

sub new {
    my( $class, $runtime, $args ) = @_;

    return $class->SUPER::new( $args );
}

sub type { 1 }
sub is_defined { 1 }
sub is_string { 0 }
sub is_float { 0 }
sub is_integer { 0 }
sub is_overloaded { 0 }
sub is_blessed { $_[0]->{stash} ? 1 : 0 }
sub is_overloaded_value { $_[0]->{stash} && $_[0]->{stash}->has_overloading }
sub overload_table { $_[0]->{stash}->overload_table }
sub set_stash { $_[0]->{stash} = $_[1] }

sub get_length_int {
    my( $self, $runtime ) = @_;

    return $self->as_scalar( $runtime )->get_length_int( $runtime );
}

sub _symbolic_reference {
    my( $self, $runtime, $sigil ) = @_;

    if( $runtime->{_lex}{hints} & 0x00000002 ) {
        my $e = Language::P::Toy::Exception->new
                    ( { message  => "Can't use symbolic references while \"strict ref\" in use",
                        } );
        $runtime->throw_exception( $e, 1 );
    }

    my $name = $self->as_string( $runtime );
    # TODO probably does not work
    if( $name !~ /::|'/ ) {
        $name = $runtime->{_lex}{package} . '::' . $name;
    }

    # TODO must handle punctuation variables and other special cases
    return $runtime->symbol_table->get_symbol( $runtime, $name, $sigil, 1 );
}

sub dereference_scalar {
    my( $self, $runtime ) = @_;

    return _symbolic_reference( $self, $runtime, '$' );
}

sub dereference_hash {
    my( $self, $runtime ) = @_;

    return _symbolic_reference( $self, $runtime, '%' );
}

sub dereference_array {
    my( $self, $runtime ) = @_;

    return _symbolic_reference( $self, $runtime, '@' );
}

sub dereference_glob {
    my( $self, $runtime ) = @_;

    return _symbolic_reference( $self, $runtime, '*' );
}

sub dereference_subroutine {
    my( $self, $runtime ) = @_;

    return _symbolic_reference( $self, $runtime, '&' );
}

sub dereference_io {
    my( $self, $runtime ) = @_;

    return _symbolic_reference( $self, $runtime, 'I' );
}

sub vivify_scalar {
    my( $self, $runtime ) = @_;

    return _symbolic_reference( $self, $runtime, '$' );
}

sub vivify_array {
    my( $self, $runtime ) = @_;

    return _symbolic_reference( $self, $runtime, '@' );
}

sub vivify_hash {
    my( $self, $runtime ) = @_;

    return _symbolic_reference( $self, $runtime, '%' );
}

sub unimplemented {
    my $m = $_[0];
    return sub { Carp::confess( "Unimplemented: $m!\n" ) };
}

foreach my $name ( @METHODS ) {
    no strict 'refs';
    *{$name} = unimplemented( $name );
}

1;
