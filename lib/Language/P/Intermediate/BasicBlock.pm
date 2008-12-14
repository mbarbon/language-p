package Language::P::Intermediate::BasicBlock;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(bytecode start_label start_stack_size) );

use Language::P::Assembly qw(label);

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    push @{$self->bytecode}, label( $self->start_label );

    return $self;
}

1;
