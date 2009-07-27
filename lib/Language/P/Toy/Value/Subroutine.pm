package Language::P::Toy::Value::Subroutine;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Code);

__PACKAGE__->mk_ro_accessors( qw(name prototype) );

sub type { 6 }
sub is_subroutine { 1 }

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    # for @_
    $self->{stack_size} ||= 1;

    return $self;
}

sub call {
    my( $self, $runtime, $pc, $context ) = @_;
    my $args = pop @{$runtime->{_stack}};

    $self->SUPER::call( $runtime, $pc, $context );

    my( $stack, $frame ) = ( $runtime->{_stack}, $runtime->{_frame} );

    $stack->[$frame - 3] = $args;
}

package Language::P::Toy::Value::Subroutine::Stub;

use strict;
use warnings;
use base qw(Language::P::Toy::Value::Subroutine);

sub call { Carp::confess( "Called subroutine stub" ) }
sub is_defined { 0 }

1;
