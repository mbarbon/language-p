package Language::P::Intermediate::Transform;

use strict;
use warnings;
use parent qw(Language::P::Object);

__PACKAGE__->mk_accessors( qw(_current) );

use Language::P::Constants qw(:all);
use Language::P::Opcodes qw(:all);
use Language::P::Assembly qw(:all);

sub all_to_linear {
    my( $self, $code_segments ) = @_;

    to_linear( $self, $_ ) foreach @$code_segments;

    return $code_segments;
}

sub _linearize {
    my( $bytecode, $op ) = @_;
    my $op_flags = $OP_ATTRIBUTES{$op->opcode_n}->{flags};

    if(    $op->opcode_n == OP_GET
        || $op->opcode_n == OP_SET
        || $op->opcode_n == OP_PHI ) {
        return;
    } elsif( $op->parameters ) {
        foreach my $parm ( @{$op->parameters} ) {
            _linearize( $bytecode, $parm );
        }
    }

    if(    ( $op_flags & Language::P::Opcodes::FLAG_UNARY )
        && ( $op_flags & Language::P::Opcodes::FLAG_VARIADIC ) ) {
        # TODO accessors
        $op->attributes->{arg_count} = $op->parameters ? @{$op->parameters} : 0;
    }

    # TODO accessors
    $op->{parameters} = undef;

    push @$bytecode, $op;
}

sub _to_linear {
    my( $bb ) = @_;
    my $bytecode = $bb->bytecode;
    my @linearized;

    foreach my $op ( @$bytecode ) {
        _linearize \@linearized, $op;
    }

    $bb->set_bytecode( \@linearized );
}

sub to_linear {
    my( $self, $code_segment ) = @_;

    _to_linear( $_ ) foreach @{$code_segment->basic_blocks};

    return $code_segment;
}

sub all_to_tree {
    my( $self, $code_segments ) = @_;

    _ssa_to_tree( $self, $_ ) foreach @$code_segments;

    return $code_segments;
}

sub to_tree {
    my( $self, $code_segment ) = @_;
    my $ssa = $self->to_ssa( $code_segment );

    return _ssa_to_tree( $self, $ssa );
}

sub _ssa_to_tree {
    my( $self, $ssa ) = @_;

    $self->_current( $ssa );
    $ssa->find_alive_blocks;

    foreach my $block ( @{$ssa->basic_blocks} ) {
        next if $block->dead && !$ssa->is_regex;
        my $jump = $block->bytecode->[-1];
        if(    $jump->is_jump
            && $jump->opcode_n != OP_JUMP ) {
            my $new_cond = opcode_npam( $jump->opcode_n, undef,
                                        $jump->parameters,
                                        to => $jump->true );
            my $new_jump = opcode_nm( OP_JUMP, to => $jump->false );

            $block->bytecode->[-1] = $new_cond;
            push @{$block->bytecode}, $new_jump;
        } elsif( $jump->opcode_n == OP_RX_QUANTIFIER ) {
            my $new_quant = # TODO clone
                opcode_nm( OP_RX_QUANTIFIER,
                           min => $jump->min, max => $jump->max,
                           greedy => $jump->greedy,
                           group => $jump->group,
                           to => $jump->true,
                           subgroups_start => $jump->subgroups_start,
                           subgroups_end => $jump->subgroups_end );
            my $new_jump = opcode_nm( OP_JUMP, to => $jump->false );

            $block->bytecode->[-1] = $new_quant;
            push @{$block->bytecode}, $new_jump;
        }

        my $op_off = 0;
        while( $op_off <= $#{$block->bytecode} ) {
            my $op = $block->bytecode->[$op_off];
            ++$op_off;
            next if    $op->opcode_n != OP_SET
                    || $op->parameters->[0]->opcode_n != OP_PHI;

            my $parameters = $op->parameters->[0]->parameters;
            my $result_slot = $op->slot;

            for( my $i = 0; $i < @$parameters; $i += 3 ) {
                my( $label, $variable, $slot ) = @{$parameters}[ $i, $i + 1, $i + 2];
                my( $block_from ) = grep $_ eq $label,
                                         @{$ssa->basic_blocks};
                my $op_from_off = $#{$block_from->bytecode};

                # find the jump coming to this block
                while( $op_from_off >= 0 ) {
                    my $op_from = $block_from->bytecode->[$op_from_off];
                    last if    $op_from->is_jump
                            && $op_from->to eq $block;
                    --$op_from_off;
                }

                die "Can't find jump: ", $block_from->start_label,
                    " => ", $block->start_label
                    if $op_from_off < 0;

                # add SET nodes to rename the variables
                splice @{$block_from->bytecode}, $op_from_off, 0,
                       opcode_npam( OP_SET, $op->pos,
                                    [ opcode_npm( OP_GET, $op->pos,
                                                  index => $variable,
                                                  slot  => $slot ) ],
                                    index => $op->index,
                                    slot  => $result_slot )
                    if $op->index != $variable;
            }

            --$op_off;
            splice @{$block->bytecode}, $op_off, 1;
        }
    }

    return $ssa;
}

1;
