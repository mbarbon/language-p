package Language::P::Value::Any;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use Carp;

our @METHODS = qw(as_integer as_string as_scalar as_boolean_int

                  get_item iterator iterator_from push get_count

                  call

                  dereference_scalar dereference_hash
                  dereference_array dereference_typeglob
                  dereference_subroutine dereference_io
                  dereference
                  );

sub type { 1 }

sub unimplemented { Carp::confess( "Unimplemented!\n" ) }

foreach my $name ( @METHODS ) {
    no strict 'refs';
    *{$name} = \&unimplemented;
}

1;
