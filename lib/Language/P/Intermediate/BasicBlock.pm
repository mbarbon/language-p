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

sub _change_successor {
    my( $self, $from, $to ) = @_;

    # remove $from from successors and insert $to
    foreach my $succ ( @{$self->successors} ) {
        if( $succ == $from ) {
            $succ = $to;
            Scalar::Util::weaken( $succ );
            last;
        }
    }

    # patch jump target to $to
    my $jump = $self->bytecode->[-1];
    if( $jump->{opcode_n} == OP_JUMP ) {
        $jump->{attributes}->{to} = $to;
    } elsif( $jump->{attributes}->{true} == $from ) {
        $jump->{attributes}->{true} = $to;
    } elsif( $jump->{attributes}->{false} == $from ) {
        $jump->{attributes}->{false} = $to;
    } else {
        die "Could not backpatch jump target";
    }

    # fix up predecessors
    $to->add_predecessor( $self );
}

sub add_jump {
    my( $self, $op, @to ) = @_;

    if(    $op->{opcode_n} == OP_JUMP && @{$self->bytecode} == 1
        && @{$self->predecessors} ) {
        $to[0] = $to[0]->successors->[0] until @{$to[0]->bytecode};
        foreach my $pred ( @{$self->predecessors} ) {
            _change_successor( $pred, $self, $to[0] );
        }

        # keep track where this block goes
        $self->add_successor( $to[0] );
        undef @{$self->bytecode};

        return;
    }

    push @{$self->bytecode}, $op;
    foreach my $to ( @to ) {
        $self->add_successor( $to );
        $to->add_predecessor( $self );
        # FIXME either move empty-block optimization later
        #       or backpatch goto/redo/last/... labels in parse tree!
        _change_successor( $self, $to, $to->successors->[0] )
            unless @{$to->bytecode};
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
