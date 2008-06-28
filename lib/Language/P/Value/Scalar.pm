package Language::P::Value::Scalar;

use strict;
use warnings;
use base qw(Language::P::Value::Any);

sub type { 5 }

sub as_scalar { return $_[0] }

sub assign_iterator {
    my( $self, $iter ) = @_;

    die unless $iter->next; # FIXME
    $self->assign( $iter->item );
}

1;
