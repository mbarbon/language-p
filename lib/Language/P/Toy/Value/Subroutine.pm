package Language::P::Toy::Value::Subroutine;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Code);

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

sub assign {
    my( $self, $runtime, $other ) = @_;

    die "PANIC" unless $other->isa( 'Language::P::Toy::Value::Subroutine' );

    bless $self, ref $other;
    %$self = %$other;
}

sub call {
    my( $self, $runtime, $pc, $context ) = @_;
    my $args = pop @{$runtime->{_stack}};

    $self->SUPER::call( $runtime, $pc, $context );

    my( $stack, $frame ) = ( $runtime->{_stack}, $runtime->{_frame} );

    $stack->[$frame - 3] = $args;

    return 0;
}

sub tail_call {
    my( $self, $runtime, $pc, $context ) = @_;
    my $args = $runtime->{_stack}->[$runtime->{_frame} - 3 - 0];
    # TODO check that we're in a subroutine and outside an eval
    $runtime->exit_subroutine;
    my $rpc = $runtime->call_return;

    $self->SUPER::call( $runtime, $rpc, $context );

    my( $stack, $frame ) = ( $runtime->{_stack}, $runtime->{_frame} );

    $stack->[$frame - 3] = $args;

    return 0;
}

package Language::P::Toy::Value::Subroutine::Stub;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Subroutine);

sub call {
    my( $self, $runtime, $pc, $context ) = @_;
    my $msg = sprintf "Undefined subroutine &%s called", $self->name;
    my $exc = Language::P::Toy::Exception->new( { message => $msg } );

    $runtime->throw_exception( $exc, 1 );
}

sub is_defined { 0 }

1;
