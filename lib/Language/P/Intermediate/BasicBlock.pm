package Language::P::Intermediate::BasicBlock;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(bytecode start_label start_stack_size
                                 predecessors successors) );

use Scalar::Util qw();
use Language::P::Assembly qw(label);
use Language::P::Opcodes qw(OP_JUMP);

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    push @{$self->bytecode}, label( $self->start_label )
      unless @{$self->bytecode};
    $self->{predecessors} ||= [];
    $self->{successors} ||= [];

    return $self;
}

sub add_jump {
    my( $self, $op, @to ) = @_;

    if( $op->{opcode_n} == OP_JUMP && @{$self->bytecode} == 1 ) {
        foreach my $pred ( @{$self->predecessors} ) {
            # remove $self from successors and insert $to[0]
            foreach my $succ ( @{$pred->successors} ) {
                if( $succ == $self ) {
                    $succ = $to[0];
                    Scalar::Util::weaken( $succ );
                    last;
                }
            }

            # patch jump target to $to[0]
            my $jump = $pred->bytecode->[-1];
            if( $jump->{opcode_n} == OP_JUMP ) {
                $jump->{attributes}->{to} = $to[0];
            } elsif( $jump->{attributes}->{true} == $self ) {
                $jump->{attributes}->{true} = $to[0];
            } elsif( $jump->{attributes}->{false} == $self ) {
                $jump->{attributes}->{false} = $to[0];
            } else {
                die "Could not backpatch jump target";
            }

            # fix up predecessors
            $to[0]->add_predecessor( $pred );
        }

        undef @{$self->bytecode};

        return;
    }

    push @{$self->bytecode}, $op;
    foreach my $to ( @to ) {
        $self->add_successor( $to );
        $to->add_predecessor( $self );
    }
}

sub add_predecessor {
    my( $self, $block ) = @_;
    return if grep $block == $_, @{$self->predecessors};

    push @{$self->predecessors}, $block;
    Scalar::Util::weaken( $self->predecessors->[-1] );
}

sub add_successor {
    my( $self, $block ) = @_;
    return if grep $block == $_, @{$self->successors};

    push @{$self->successors}, $block;
    Scalar::Util::weaken( $self->successors->[-1] );
}

1;
