package Language::P::Intermediate::BasicBlock;

use strict;
use warnings;
use parent qw(Language::P::Object);

__PACKAGE__->mk_ro_accessors( qw(bytecode start_label scope
                                 predecessors successors dead) );

sub set_scope { $_[0]->{scope} = $_[1] }

use Language::P::Opcodes qw(OP_JUMP);

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{predecessors} ||= [];
    $self->{successors} ||= [];
    $self->{bytecode} ||= [];

    return $self;
}

sub new_from_label {
    return $_[0]->new( { start_label   => $_[1],
                         scope         => $_[2],
                         dead          => $_[3],
                         } );
}

sub _change_successor {
    my( $self, $from, $to ) = @_;

    # remove $from from successors and insert $to
    foreach my $succ ( @{$self->successors} ) {
        if( $succ == $from ) {
            $succ = $to;
            last;
        }
    }

    # patch jump target to $to
    my $jump = $self->bytecode->[-1];
    if( $jump->{opcode_n} == OP_JUMP && $jump->to == $from ) {
        $jump->set_to( $to );
    } elsif( $jump->true == $from ) {
        $jump->set_true( $to );
    } elsif( $jump->false == $from ) {
        $jump->set_false( $to );
    } else {
        require Carp;

        Carp::confess( "Could not backpatch jump target ", $from->start_label,
                       " for block ", $self->start_label );
    }

    # fix up predecessors
    $to->add_predecessor( $self );
    # remove $self from $from predecessors
    foreach my $i ( 0 .. $#{$from->{predecessors}} ) {
        if( $from->{predecessors}[$i] == $self ) {
            splice @{$from->{predecessors}}, $i, 1;
            last;
        }
    }
}

sub add_jump {
    my( $self, $op, @to ) = @_;

    if(    $op->{opcode_n} == OP_JUMP && @{$self->bytecode} == 0
        && @{$self->predecessors} ) {
        $to[0] = $to[0]->successors->[0] while    @{$to[0]->successors}
                                               && !@{$to[0]->bytecode};

        my @pred = @{$self->predecessors};
        foreach my $pred ( @pred ) {
            _change_successor( $pred, $self, $to[0] );
        }

        # keep track where this block goes
        $self->add_successor( $to[0] );
    } else {
        add_jump_unoptimized( $self, $op, @to );
    }
}

sub add_jump_unoptimized {
    my( $self, $op, @to ) = @_;

    push @{$self->bytecode}, $op;
    return if $self->dead == 2;
    foreach my $to ( @to ) {
        $self->add_successor( $to );
        $to->add_predecessor( $self );
        # FIXME either move empty-block optimization later
        #       or backpatch goto/redo/last/... labels in parse tree!
        _change_successor( $self, $to, $to->successors->[0] )
            if !@{$to->bytecode} && @{$to->successors};
    }
}

sub add_predecessor {
    my( $self, $block ) = @_;
    return if grep $block == $_, @{$self->predecessors};

    push @{$self->predecessors}, $block;
}

sub add_successor {
    my( $self, $block ) = @_;
    return if grep $block == $_, @{$self->successors};

    push @{$self->successors}, $block;
}

1;
