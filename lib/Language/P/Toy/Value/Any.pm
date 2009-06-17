package Language::P::Toy::Value::Any;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Carp;

our @METHODS = qw(as_integer as_float as_string as_scalar as_boolean_int
                  localize

                  get_item iterator iterator_from push get_count

                  call

                  dereference_scalar dereference_hash
                  dereference_array dereference_typeglob
                  dereference_subroutine dereference_io
                  dereference

                  reference_type
                  );

sub type { 1 }
sub is_defined { 1 }

sub unimplemented {
    my $m = $_[0];
    return sub { Carp::confess( "Unimplemented: $m!\n" ) };
}

foreach my $name ( @METHODS ) {
    no strict 'refs';
    *{$name} = unimplemented( $name );
}

1;
