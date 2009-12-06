package Language::P::Toy::Opcodes::Regex;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(o_rx_start_match o_rx_accept o_rx_exact o_rx_start_group
                    o_rx_quantifier o_rx_capture_start o_rx_capture_end o_rx_try
                    o_rx_start_special o_rx_end_special
                    o_rx_match);
our %EXPORT_TAGS =
  ( opcodes => \@EXPORT_OK,
    );

sub v(@) {
    return;
    print @_;
}

sub vv(@) {
    return;
    print @_;
}

sub d(@) {
    require Data::Dumper;

    return Data::Dumper::Dumper( @_ );
}

sub _save_groups {
    my( $cxt, $op, $clear ) = @_;
    my @saved;
    my $groups = { start               => $op->{subgroups_start},
                   data                => \@saved,
                   last_closed_capture => $cxt->{last_closed_capture},
                   last_open_capture   => $cxt->{last_open_capture},
                   };

    vv "Saving $op->{subgroups_start}-$op->{subgroups_end}\n";
    for( my $i = $op->{subgroups_start}; $i < $op->{subgroups_end}; ++$i ) {
        my $g = $clear ? [-1, -1] : $cxt->{captures}[$i] || [-1, -1];
        push @saved, [ $g->[0], $g->[1] ];
    }

    return $groups;
}

sub _restore_groups {
    my( $cxt, $groups ) = @_;
    vv d $groups, $cxt->{captures};

    my $index = $groups->{start};
    foreach my $g ( @{$groups->{data}} ) {
        $cxt->{captures}[$index] = [ @$g ];
        ++$index;
    }

    vv "Restored $groups->{start}-$index\n";
    $cxt->{last_closed_capture} = $groups->{last_closed_capture};
    $cxt->{last_open_capture} = $groups->{last_open_capture};
}

sub _start_capture {
    my( $cxt, $group ) = @_;

    v "SCapt: $group: $cxt->{pos}\n";

    # null the captures between the last open capture and this group
    for( my $i = $cxt->{last_open_capture} + 1; $i < $group; ++$i ) {
        $cxt->{captures}[$i][0] = $cxt->{captures}[$i][1] = -1;
    }

    # save group start
    $cxt->{captures}[$group][0] = $cxt->{pos};
    $cxt->{captures}[$group][1] = -1;

    # set ourselves as the last open capture
    $cxt->{last_open_capture} = $group if $cxt->{last_open_capture} < $group;
}

sub _end_capture {
    my( $cxt, $group ) = @_;

    v "ECapt: $group (last: $cxt->{last_closed_capture}): $cxt->{pos}\n";

    # save group end
    $cxt->{captures}[$group][1] = $cxt->{pos};

    # set ourselves as the last capture
    $cxt->{last_closed_capture} = $group;
}

sub _backtrack {
    my( $runtime, $cxt ) = @_;
    my $states = $cxt->{states};

    if( @$states ) {
        v "Pop state\n";
        my $bt = pop @$states;
        ( my $pc, $cxt->{pos} ) = ( $bt->{ret_pc}, $bt->{pos} );
        if( $pc >= 0 ) {
            if( $bt->{group_count} >= 0 ) {
                vv "Restoring $bt->{group_count}\n";
                $#{$cxt->{groups}} = $bt->{group_count} - 1;
            }
            _restore_groups( $cxt, $bt->{saved_groups} ) if $bt->{saved_groups};
            v "Bt pc: $pc pos: $cxt->{pos}\n";
            return $pc;
        }
    }

    v "Pop\n";
    my $stack = $cxt->{states_backtrack};
    if( @$stack ) {
        my $state_size = pop @$stack;
        $#{$cxt->{states}} = $state_size - 1;
        pop @{$cxt->{groups}};

        return _backtrack( $runtime, $cxt );
    } else {
        my $rpc = $runtime->call_return;
        push @{$runtime->{_stack}}, { matched => 0 };

        return $rpc + 1;
    }
}

sub o_rx_match {
    my( $op, $runtime, $pc ) = @_;
    my $pattern = pop @{$runtime->{_stack}};
    my $scalar = pop @{$runtime->{_stack}};

    my $match = $pattern->match( $runtime, $scalar->as_string( $runtime ) );

    push @{$runtime->{_stack}}, Language::P::Toy::Value::StringNumber->new
                                    ( $runtime, { integer => $match->{matched} } );

    return $pc + 1;
}

sub o_rx_start_match {
    my( $op, $runtime, $pc ) = @_;
    my $string = $runtime->{_stack}[$runtime->{_frame} - 3];
    my $start = $runtime->{_stack}[$runtime->{_frame} - 4];
    my $cxt = { string               => $string,
                pos                  => $start,
                length               => length( $string ),
                states_backtrack     => [],
                states               => [],
                groups               => [],
                captures             => [],
                last_closed_capture  => -1,
                last_open_capture    => -1,
                };
    push @{$runtime->{_stack}}, $cxt;

    v "String '$string', start $start\n";

    return $pc + 1;
}

sub o_rx_accept {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];
    my $rpc = $runtime->call_return;

    # null-out unclosed groups
    for( my $i = $cxt->{last_open_capture} + 1; $i < $op->{groups}; ++$i ) {
        $cxt->{captures}[$i][0] = $cxt->{captures}[$i][1] = -1;
    }
    # save captured strings
    my @strings;
    foreach my $capt ( @{$cxt->{captures}} ) {
        push @strings, $capt->[1] == -1 ? undef :
             substr $cxt->{string}, $capt->[0], $capt->[1] - $capt->[0];
    }

    push @{$runtime->{_stack}},
      { matched         => 1,
        match_end       => $cxt->{pos},
        captures        => $cxt->{captures},
        string_captures => \@strings,
        };

    return $rpc + 1;
}

sub o_rx_exact {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    v "Exact '$op->{string}' at $cxt->{pos}\n";
    if(    substr( $cxt->{string}, $cxt->{pos}, $op->{length} )
        ne $op->{string} ) {
        return _backtrack( $runtime, $cxt );
    }
    $cxt->{pos} += $op->{length};

    return $pc + 1;
}

sub o_rx_start_group {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    # push a new group context
    push @{$cxt->{groups}},
         { repeat      => -1,
           last_match  => -1,
           };
    # add a new backtrack group
    push @{$cxt->{states_backtrack}}, scalar @{$cxt->{states}};

    return $op->{to};
}

sub o_rx_quantifier {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];
    my $count = ++$cxt->{groups}[-1]->{repeat};

    v "Quantifier at $pc (pos: $cxt->{pos}, rep: $count)\n";
    _end_capture( $cxt, $op->{group} ) if $count > 0 && $op->{group} >= 0;

    if( $count == $op->{max} ) {
        v "Reached max limit\n";
        pop @{$cxt->{groups}};
        return $pc + 1;
    }

    # try to continue match if matched twice at the same position
    # (i.e. zero-length match)
    if( $cxt->{pos} == $cxt->{groups}[-1]->{last_match} ) {
        v "Zero-length match ($count)\n";
        return $pc + 1;
    }

    my $groups = defined $op->{subgroups_start} && ( $count == 0 || $count >= $op->{min} ) ?
                     _save_groups( $cxt, $op, $count == 0 ) : undef;

    if( $count == 0 && $op->{min} > 0 ) {
        # force failure of the group on backtrack
        push @{$cxt->{states}},
             { pos           => $cxt->{pos},
               ret_pc        => -2, # so $pc + 1 == -1
               group_count   => -1,
               saved_groups  => $groups,
               };
    } elsif( $count >= $op->{min} ) {
        push @{$cxt->{states}},
             { pos           => $cxt->{pos},
               ret_pc        => $pc + 1,
               group_count   => -1 + scalar @{$cxt->{groups}},
               saved_groups  => $groups,
               };
    }

    $cxt->{groups}[-1]->{last_match} = $cxt->{pos};

    # if nongreedy, match at least min
    if( !$op->{greedy} && $count >= $op->{min} ) {
        # TODO why pops the group?
        pop @{$cxt->{groups}};
        return $pc + 1;
    }

    _start_capture( $cxt, $op->{group} ) if $op->{group} >= 0;

    return $op->{to};
}

sub o_rx_try {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    my $groups = defined $op->{subgroups_start} ?
                     _save_groups( $cxt, $op, 0 ) : undef;

    push @{$cxt->{states}},
         { pos           => $cxt->{pos},
           ret_pc        => $op->{to},
           group_count   => scalar @{$cxt->{groups}},
           saved_groups  => $groups,
           };

    return $pc + 1;
}

sub o_rx_capture_start {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    _start_capture( $cxt, $op->{group} );

    return $pc + 1;
}

sub o_rx_capture_end {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    _end_capture( $cxt, $op->{group} );

    return $pc + 1;
}

sub o_rx_start_special {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    if( $cxt->{pos} != 0 ) {
        return _backtrack( $runtime, $cxt );
    }

    return $pc + 1;
}

sub o_rx_end_special {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    if(    $cxt->{pos} != $cxt->{length}
        && (    $cxt->{pos} != $cxt->{length} - 1
             || substr( $cxt->{string}, -1, 1 ) ne "\n" ) ) {
        return _backtrack( $runtime, $cxt );
    }

    return $pc + 1;
}

1;
