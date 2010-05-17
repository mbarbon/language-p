package Language::P::Toy::Value::Any;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(stash) );

use Carp;

our @METHODS = qw(as_integer as_float as_string as_scalar as_boolean_int
                  set_integer set_float set_string
                  localize pre_increment post_increment pre_decrement
                  post_decrement

                  get_item iterator iterator_from push_value get_count
                  push_list pop_value unshift_list shift_value slice

                  call find_method

                  dereference_scalar dereference_hash
                  dereference_array dereference_typeglob
                  dereference_subroutine dereference_io
                  dereference vivify_scalar vivify_array vivify_hash

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
sub is_blessed { $_[0]->{stash} ? 1 : 0 }
sub set_stash { $_[0]->{stash} = $_[1] }

sub get_length_int {
    my( $self, $runtime ) = @_;

    return $self->as_scalar( $runtime )->get_length_int( $runtime );
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
