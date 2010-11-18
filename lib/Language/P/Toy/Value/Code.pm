package Language::P::Toy::Value::Code;

use strict;
use warnings;
use parent qw(Language::P::Toy::Value::Any);

use Language::P::Constants qw(VALUE_SCALAR VALUE_ARRAY VALUE_HASH);

__PACKAGE__->mk_ro_accessors( qw(bytecode stack_size lexicals closed
                                 lexical_init scopes) );

sub type { 9 }
sub is_subroutine { 0 }
sub name { undef }

sub new {
    my( $class, $runtime, $args ) = @_;
    my $self = $class->SUPER::new( $runtime, $args );

    $self->{stack_size} ||= 0;
    $self->{closed} ||= [];
    $self->{lexical_init} ||= [];
    $self->{scopes} ||= [];

    return $self;
}

sub call {
    my( $self, $runtime, $pc, $context ) = @_;
    my $frame = $runtime->push_frame( $self->stack_size + 2 );

    my $stack = $runtime->{_stack};
    if( $self->lexicals ) {
        my $pad = $self->lexicals->new_scope( $runtime, undef );
        $stack->[$frame - 1] = $pad;
    } else {
        $stack->[$frame - 1] = 'no_pad';
    }
    if( $self->stack_size ) {
        my $st = $self->is_subroutine ? 1 : 0; # skip @_
        for( my $i = $st; $i <= $#{$self->lexical_init}; ++$i ) {
            if( $self->lexical_init->[$i] == VALUE_SCALAR ) {
                $stack->[$frame - 3 - $i] = Language::P::Toy::Value::Undef->new;
            } elsif( $self->lexical_init->[$i] == VALUE_ARRAY ) {
                $stack->[$frame - 3 - $i] = Language::P::Toy::Value::Array->new;
            } elsif( $self->lexical_init->[$i] == VALUE_HASH ) {
                $stack->[$frame - 3 - $i] = Language::P::Toy::Value::Hash->new;
            }
        }
    }
    $stack->[$frame - 2] = [ $pc, $runtime->{_bytecode}, $context,
                             $runtime->{_code}, $runtime->{_lex}, undef ];

    $runtime->set_bytecode( $self->bytecode );
    # FIXME encapsulation
    $runtime->{_code} = $self;

    return 0;
}

sub as_boolean_int { return 1 }

1;
