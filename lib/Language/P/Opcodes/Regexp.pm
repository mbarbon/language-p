package Language::P::Opcodes::Regexp;

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
    my $groups = { start    => $op->{subgroups_start},
                   data     => \@saved,
                   last_cap => $cxt->{last_cap},
                   last_open=> $cxt->{last_open},
                   };

    vv "Saving $op->{subgroups_start}-$op->{subgroups_end}\n";
    for( my $i = $op->{subgroups_start}; $i < $op->{subgroups_end}; ++$i ) {
        my $g = $clear ? [-1, -1] : $cxt->{capt}[$i] || [-1, -1];
        push @saved, [ $g->[0], $g->[1] ];
    }

    return $groups;
}

sub _restore_groups {
    my( $cxt, $groups ) = @_;
    vv d $groups, $cxt->{capt};

    my $index = $groups->{start};
    foreach my $g ( @{$groups->{data}} ) {
        $cxt->{capt}[$index] = [ @$g ];
        ++$index;
    }

    vv "Restored $groups->{start}-$index\n";
    $cxt->{last_cap} = $groups->{last_cap};
    $cxt->{last_open} = $groups->{last_open};
}

sub _start_capture {
    my( $cxt, $group ) = @_;

    v "SCapt: $group: $cxt->{pos}\n";

    for( my $i = $cxt->{last_open} + 1; $i < $group; ++$i ) {
        $cxt->{capt}[$i][0] = $cxt->{capt}[$i][1] = -1;
    }

    $cxt->{capt}[$group][0] = $cxt->{pos};
    $cxt->{capt}[$group][1] = -1;

    $cxt->{last_open} = $group if $cxt->{last_open} < $group;
}

sub _end_capture {
    my( $cxt, $group ) = @_;

    $cxt->{capt}[$group][1] = $cxt->{pos};

    v "ECapt: $group (last: $cxt->{last_cap}): $cxt->{pos}\n";
    for( my $i = $cxt->{last_open} + 1; $i < $group; ++$i ) {
        $cxt->{capt}[$i][0] = $cxt->{capt}[$i][1] = -1;
    }

    $cxt->{last_cap} = $group;
}

sub _backtrack {
    my( $runtime, $cxt ) = @_;
    my $st = $cxt->{st};

    if( @$st ) {
        v "Pop state\n";
        my $bt = pop @$st;
        ( my $pc, $cxt->{pos} ) = ( $bt->{r}, $bt->{s} );
        if( $pc >= 0 ) {
            if( $bt->{btg} ) {
                vv "Restoring $bt->{btg}\n";
                $cxt->{btg} = $bt->{btg};
            }
            _restore_groups( $cxt, $bt->{g} ) if $bt->{g};
            v "Bt pc: $pc pos: $cxt->{pos}\n";
            return $pc;
        }
    }

    v "Pop\n";
    my $stack = $cxt->{stack};
    if( @$stack ) {
        $st = $cxt->{st} = pop @$stack;
        $cxt->{btg} = $cxt->{btg}->{btg};

        return _backtrack( $runtime, $cxt );
    } else {
        my $rpc = $runtime->call_return;
        push @{$runtime->{_stack}}, { matched => 0 };

        return $rpc + 1;
    }
}

sub o_rx_match {
    my( $op, $runtime, $pc ) = @_;
    my $scalar = pop @{$runtime->{_stack}};
    my $pattern = pop @{$runtime->{_stack}};

    my $match = $pattern->match( $runtime, $scalar->as_string );

    push @{$runtime->{_stack}}, Language::P::Value::StringNumber->new
                                    ( { integer => $match->{matched} } );

    return $pc + 1;
}

sub o_rx_start_match {
    my( $op, $runtime, $pc ) = @_;
    my $string = $runtime->{_stack}[-6]; # FIXME offset
    my $start = $runtime->{_stack}[-7]; # FIXME offset
    my @stack;
    my $cxt = { string   => $string,
                pos      => $start,
                length   => length( $string ),
                stack    => \@stack,
                st       => \@stack,
                btg      => undef,
                capt     => [],
                last_cap => -1,
                last_open=> -1,
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
    for( my $i = $cxt->{last_open} + 1; $i < $op->{groups}; ++$i ) {
        $cxt->{capt}[$i][0] = $cxt->{capt}[$i][1] = -1;
    }

    push @{$runtime->{_stack}}, { matched   => 1,
                                  match_end => $cxt->{pos},
                                  captures  => $cxt->{capt} };

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
    my $st = $cxt->{st};

    # push a new group context
    $cxt->{btg} = { c   => -1,
                    st  => [],
                    btg => $cxt->{btg},
                    lm  => -1,
                    };
    # add a new backtrack group
    my $nst = $cxt->{btg}->{st};
    push @{$cxt->{stack}}, $st;
    $cxt->{st} = $nst;

    return $op->{to};
}

sub o_rx_quantifier {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];
    my $c = $cxt->{btg}->{c} += 1;

    v "Quantifier at $pc (pos: $cxt->{pos}, rep: $c) btg: $cxt->{btg} old: ${$cxt->{btg}->{btg} ? \$cxt->{btg}->{btg} : \''}\n";
    _end_capture( $cxt, $op->{group} ) if $c > 0 && defined $op->{group};

    if( $c == $op->{max} ) {
        v "Reached max limit\n";
        $cxt->{btg} = $cxt->{btg}->{btg};
        return $pc + 1;
    }

    # try to continue match if matched twice at the same position
    # (i.e. zero-length match)
    if( $cxt->{pos} == $cxt->{btg}->{lm} ) {
        v "Zero-length match ($c)\n";
        $cxt->{btg} = $cxt->{btg}->{btg};
        return $pc + 1;
    }

    my $groups = defined $op->{subgroups_start} && ( $c == 0 || $c >= $op->{min} ) ?
                     _save_groups( $cxt, $op, $c == 0 ) : undef;

    if( $c == 0 && $op->{min} > 0 ) {
        # force failure of the group on backtrack
        push @{$cxt->{st}}, { s => $cxt->{pos},
                              r => -2,
                              g => $groups,
                              };
    } elsif( $c >= $op->{min} ) {
        push @{$cxt->{st}}, { s => $cxt->{pos},
                              r => $pc + 1,
                              g => $groups,
                              btg => $cxt->{btg}->{btg},
                              };
    }

    $cxt->{btg}->{lm} = $cxt->{pos};

    # if nongreedy, match at least min
    if( !$op->{greedy} && $c >= $op->{min} ) {
        $cxt->{btg} = $cxt->{btg}->{btg};
        return $pc + 1;
    }

    _start_capture( $cxt, $op->{group} ) if defined $op->{group};

    return $op->{to};
}

sub o_rx_try {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    my $groups = defined $op->{subgroups_start} ?
                     _save_groups( $cxt, $op ) : undef;

    push @{$cxt->{st}}, { s => $cxt->{pos},
                          r => $op->{to},
                          g => $groups,
                          btg => $cxt->{btg},
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
