package Language::P::Value::Code;

use strict;
use warnings;
use base qw(Language::P::Value::Any);

__PACKAGE__->mk_ro_accessors( qw(bytecode stack_size lexicals outer) );

sub type { 9 }

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{stack_size} = 0;

    return $self;
}

sub call {
    my( $self, $runtime, $pc, $context ) = @_;
    my $frame = $runtime->push_frame( $self->stack_size + 2 );

    my $stack = $runtime->{_stack};
    if( $self->lexicals ) {
        # FIXME copy closed-over scalars
        my $pad = $self->lexicals->new_scope( undef );
        $stack->[$frame - 1] = $pad;
    } else {
        $stack->[$frame - 1] = 'no_pad';
    }
    if( $self->stack_size ) {
        # FIXME lexical values initialization
        foreach my $slot ( 0 .. $self->stack_size ) {
            $stack->[$frame - 2 - $slot] = Language::P::Value::StringNumber->new;
        }
    }
    $stack->[$frame - 2] = [ $pc, $runtime->{_bytecode}, $context ];

    $runtime->set_bytecode( $self->bytecode );
}

1;
