package Language::P::Intermediate::Code;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(type name basic_blocks outer inner) );

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{inner} = [];

    return $self;
}

1;
