package Language::P::Toy::Opcodes::Regex;

use strict;
use warnings;
use Exporter 'import';

use Language::P::Constants qw(:all);

our @EXPORT_OK = qw(o_rx_start_match o_rx_accept o_rx_exact o_rx_start_group
                    o_rx_quantifier o_rx_capture_start o_rx_capture_end o_rx_try
                    o_rx_beginning o_rx_end_or_newline o_rx_state_restore
                    o_rx_end o_rx_exact_i o_rx_word_boundary
                    o_rx_match o_rx_match_global o_rx_replace o_rx_transliterate
                    o_rx_replace_global o_rx_class o_rx_any_nonewline o_rx_any
                    o_rx_save_pos o_rx_restore_pos o_rx_fail o_rx_backtrack
                    o_rx_pop_state o_rx_split o_rx_split_skipspaces);

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

sub _context {
    my( $op, $runtime ) = @_;
    my $cxt = $op ? $op->{context} : 0;

    return $cxt if $cxt && $cxt != CXT_CALLER;
    return $runtime->{_stack}[$runtime->{_frame} - 2][2];
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

sub o_rx_split {
    my( $op, $runtime, $pc ) = @_;

    die 'Unimplemented';

    return $pc + 1;
}

sub o_rx_split_skipspaces {
    my( $op, $runtime, $pc ) = @_;
    my $value = pop @{$runtime->{_stack}};
    my @parts = map Language::P::Toy::Value::Scalar->new_string( $runtime, $_ ),
                    split ' ', $value->as_string( $runtime );

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::List->new( $runtime, { array => \@parts } );

    return $pc + 1;
}

sub o_rx_match {
    my( $op, $runtime, $pc ) = @_;
    my $pattern = pop @{$runtime->{_stack}};
    my $scalar = pop @{$runtime->{_stack}};
    my $cxt = _context( $op, $runtime );

    my $match = $pattern->match( $runtime, $scalar->as_string( $runtime ) );
    if( $match->{matched} ) {
        my $state = $runtime->get_last_match;
        $runtime->set_last_match( $match );

        $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = $state;
    }

    if( $cxt == CXT_SCALAR || $cxt == CXT_VOID ) {
        push @{$runtime->{_stack}},
            Language::P::Toy::Value::StringNumber->new_boolean
                ( $runtime, $match->{matched} );
    } elsif( $match->{matched} && @{$match->{string_captures}} ) {
        my @values;
        foreach my $capt ( @{$match->{string_captures}} ) {
            push @values,
                Language::P::Toy::Value::StringNumber->new
                    ( $runtime, { string => $capt } );
        }

        push @{$runtime->{_stack}},
            Language::P::Toy::Value::List->new
                ( $runtime, { array => \@values } );
    } else {
        push @{$runtime->{_stack}},
            Language::P::Toy::Value::List->new_boolean
                ( $runtime, $match->{matched} );
    }

    return $pc + 1;
}

sub o_rx_match_global {
    my( $op, $runtime, $pc ) = @_;
    my $pattern = pop @{$runtime->{_stack}};
    my $scalar = pop @{$runtime->{_stack}};
    my $cxt = _context( $op, $runtime );
    my( $pos_set, $pos ) = $scalar->get_pos;
    my $string = $scalar->as_string( $runtime );

    my $match;

    if( $cxt == CXT_SCALAR || $cxt == CXT_VOID ) {
        $match = $pattern->match( $runtime, $string, $pos, $pos_set );
        if( $match->{matched} ) {
            my $state = $runtime->get_last_match;
            $runtime->set_last_match( $match );

            $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = $state;
        }

        push @{$runtime->{_stack}},
            Language::P::Toy::Value::StringNumber->new_boolean
                ( $runtime, $match->{matched} );
    } else {
        my @values;
        my $prev;

        for(;;) {
            $match = $pattern->match( $runtime, $string, $pos );
            if( $match->{matched} ) {
                foreach my $capt ( @{$match->{string_captures}} ) {
                    push @values,
                        Language::P::Toy::Value::StringNumber->new
                            ( $runtime, { string => $capt } );
                }

                # if there aren't capture groups, add the matched substring
                if( !@{$match->{string_captures}} ) {
                    my $substr = substr $string, $match->{match_start},
                                        $match->{match_end} - $match->{match_start};
                    push @values,
                        Language::P::Toy::Value::StringNumber->new
                            ( $runtime, { string => $substr } );
                }
            } else {
                last;
            }

            $pos = $match->{match_end};
            $prev = $match;
        }

        if( $prev ) {
            my $state = $runtime->get_last_match;
            $runtime->set_last_match( $prev );

            $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = $state;
        }

        if( $op->{flags} & FLAG_RX_KEEP ) {
            $match = $prev;
        }

        push @{$runtime->{_stack}},
            Language::P::Toy::Value::List->new
                ( $runtime, { array => \@values } );
    }

    if( $match->{matched} ) {
        $scalar->set_pos( $runtime, $match->{match_end}, 0 );
    } elsif( !( $op->{flags} & FLAG_RX_KEEP ) ) {
        $scalar->set_pos( $runtime, undef, 0 );
    }

    return $pc + 1;
}

sub o_rx_replace {
    my( $op, $runtime, $pc ) = @_;
    my $replace = $op->{to};
    my $pattern = pop @{$runtime->{_stack}};
    my $scalar = pop @{$runtime->{_stack}};
    my $cxt = _context( $op, $runtime );

    my $string = $scalar->as_string( $runtime );
    my $match = $pattern->match( $runtime, $string );
    if( $match->{matched} ) {
        # save match state
        my $state = $runtime->get_last_match;
        $runtime->set_last_match( $match );

        $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = $state;

        # replace the matched string; _pc will be restored by
        # "return $pc + 1" below
        $runtime->{_pc} = $replace;
        $runtime->run;

        my $replacement = pop @{$runtime->{_stack}};

        substr $string, $match->{match_start},
               $match->{match_end} - $match->{match_start},
               $replacement->as_string( $runtime );

        $scalar->assign( $runtime, Language::P::Toy::Value::Scalar->new_string
                                       ( $runtime, $string ) );
    }

    if( $cxt == CXT_SCALAR || $cxt == CXT_VOID ) {
        push @{$runtime->{_stack}},
            Language::P::Toy::Value::StringNumber->new_boolean
                ( $runtime, $match->{matched} );
    } else {
        push @{$runtime->{_stack}},
            Language::P::Toy::Value::List->new_boolean
                ( $runtime, $match->{matched} );
    }

    return $pc + 1;
}

sub o_rx_replace_global {
    my( $op, $runtime, $pc ) = @_;
    my $replace = $op->{to};
    my $pattern = pop @{$runtime->{_stack}};
    my $scalar = pop @{$runtime->{_stack}};
    my $cxt = _context( $op, $runtime );
    my $count = 0;
    my $pos = 0;

    # save match state
    my $state = $runtime->get_last_match;
    my $string = $scalar->as_string( $runtime );
    my $last;
    my @replacements;
    for(;;) {
        my $match = $pattern->match( $runtime, $string, $pos );
        if( $match->{matched} ) {
            $runtime->set_last_match( $match );
            ++$count;
            $last = $match;
            $pos = $match->{match_end};

            # replace the matched string; _pc will be restored by
            # "return $pc + 1" below
            $runtime->{_pc} = $replace;
            $runtime->run;

            my $replacement = pop @{$runtime->{_stack}};

            push @replacements,
                 [ $match->{match_start},
                   $match->{match_end} - $match->{match_start},
                   $replacement->as_string( $runtime ) ];
        } else {
            last;
        }
    }

    foreach my $repl ( reverse @replacements ) {
        substr $string, $repl->[0], $repl->[1], $repl->[2];
    }

    $scalar->assign( $runtime, Language::P::Toy::Value::Scalar->new_string
                                   ( $runtime, $string ) );

    if( $last ) {
        $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = $state;
    }

    my $res = Language::P::Toy::Value::StringNumber->new_integer
                  ( $runtime, $count );

    if( $cxt == CXT_SCALAR || $cxt == CXT_VOID ) {
        push @{$runtime->{_stack}}, $res;
    } else {
        push @{$runtime->{_stack}},
            Language::P::Toy::Value::List->new
                ( $runtime, { array => [ $res ] } );
    }

    return $pc + 1;
}

sub o_rx_transliterate {
    my( $op, $runtime, $pc ) = @_;
    my $string = pop @{$runtime->{_stack}};
    my( $match, $replacement, $flags ) = ( $op->{match}, $op->{replacement}, $op->{flags} );
    my $s = $string->as_string( $runtime );
    my( $count, $new, $last_r ) = ( 0, '', '' );

    for( my $i = 0; $i < length $s; ++$i ) {
        my $c = substr $s, $i, 1;
        my $idx = index $match, $c;
        my $r = $c;

        if( $idx == -1 && ( $flags & 1 ) ) { # complement
            if( $flags & 2 ) { # delete
                $r = '';
            } elsif( length $replacement ) {
                $r = substr $replacement, -1, 1;
            }

            if( $last_r eq $r && ( $flags & 4 ) ) { # squeeze
                $r = '';
            } else {
                $last_r = $r;
            }

            $count += 1;
        } elsif( $idx != -1 && !( $flags & 1 ) ) {
            if( $idx >= length $replacement && ( $flags & 2 ) ) { # delete
                $r = '';
            } elsif( $idx >= length $replacement ) {
                $r = substr $replacement, -1, 1;
            } elsif( $idx < length $replacement ) {
                $r = substr $replacement, $idx, 1;
            }

            if( $last_r eq $r && ( $flags & 4 ) ) { # squeeze
                $r = '';
            } else {
                $last_r = $r;
            }

            $count += 1;
        } else {
            $last_r = '';
        }

        $new .= $r;
    }

    $string->set_string( $runtime, $new );

    push @{$runtime->{_stack}},
         Language::P::Toy::Value::Scalar->new_integer( $runtime, $count );

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

sub o_rx_exact_i {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    v "Exact (i) '$op->{string}' at $cxt->{pos}\n";
    if(    lc substr( $cxt->{string}, $cxt->{pos}, $op->{length} )
        ne lc $op->{string} ) {
        return _backtrack( $runtime, $cxt );
    }
    $cxt->{pos} += $op->{length};

    return $pc + 1;
}

sub o_rx_class {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    v "Class '$op->{elements}', '@{$op->{special}}} at $cxt->{pos}\n";
    my $chr = substr $cxt->{string}, $cxt->{pos}, 1;
    if(    $cxt->{pos} < length( $cxt->{string} )
        && (    index( $op->{elements}, $chr ) >= 0
             || grep $chr =~ $_, @{$op->{special}} ) ) {
        $cxt->{pos} += 1;

        return $pc + 1;
    }

    return _backtrack( $runtime, $cxt );
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

    my $groups = ( $count == 0 || $count >= $op->{min} ) ?
                     _save_groups( $cxt, $op, $count == 0 ) : undef;

    if( $count == 0 && $op->{min} > 0 ) {
        # force failure of the group on backtrack
        push @{$cxt->{states}},
             { pos           => $cxt->{pos},
               ret_pc        => -2, # so $pc + 1 == -1
               group_count   => -1,
               saved_groups  => $groups,
               };
    } elsif( $op->{greedy} && $count >= $op->{min} ) {
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
        push @{$cxt->{states}},
             { pos           => $cxt->{pos},
               ret_pc        => $op->{to},
               group_count   => scalar @{$cxt->{groups}},
               saved_groups  => $groups,
               };
        return $pc + 1;
    }

    _start_capture( $cxt, $op->{group} ) if $op->{group} >= 0;

    return $op->{to};
}

sub o_rx_try {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    # TODO used to save groups here, but it's probably not needed

    push @{$cxt->{states}},
         { pos           => $cxt->{pos},
           ret_pc        => $op->{to},
           group_count   => scalar @{$cxt->{groups}},
           saved_groups  => undef,
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

sub o_rx_beginning {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    if( $cxt->{pos} != 0 ) {
        return _backtrack( $runtime, $cxt );
    }

    return $pc + 1;
}

sub o_rx_end {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    if( $cxt->{pos} != $cxt->{length} ) {
        return _backtrack( $runtime, $cxt );
    }

    return $pc + 1;
}

sub o_rx_end_or_newline {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    if(    $cxt->{pos} != $cxt->{length}
        && (    $cxt->{pos} != $cxt->{length} - 1
             || substr( $cxt->{string}, -1, 1 ) ne "\n" ) ) {
        return _backtrack( $runtime, $cxt );
    }

    return $pc + 1;
}

sub o_rx_any_nonewline {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    if(    $cxt->{pos} == $cxt->{length}
        || substr( $cxt->{string}, $cxt->{pos}, 1 ) eq "\n" ) {
        return _backtrack( $runtime, $cxt );
    }
    $cxt->{pos} += 1;

    return $pc + 1;
}

sub o_rx_any {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    if( $cxt->{pos} == $cxt->{length} ) {
        return _backtrack( $runtime, $cxt );
    }
    $cxt->{pos} += 1;

    return $pc + 1;
}

sub o_rx_word_boundary {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    pos( $cxt->{string} ) = $cxt->{pos};
    if( $cxt->{string} !~ /\G\b/cg ) {
        return _backtrack( $runtime, $cxt );
    }

    return $pc + 1;
}

sub o_rx_state_restore {
    my( $op, $runtime, $pc ) = @_;
    my $old = $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}];

    $runtime->{_stack}->[$runtime->{_frame} - 3 - $op->{index}] = undef;
    $runtime->set_last_match( $old )
        if $old;

    return $pc + 1;
}

sub o_rx_save_pos {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    $cxt->{saved_pos}[$op->{index}] = $cxt->{pos};

    return $pc + 1;
}

sub o_rx_restore_pos {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    $cxt->{pos} = $cxt->{saved_pos}[$op->{index}];

    return $pc + 1;
}

sub o_rx_fail {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    return _backtrack( $runtime, $cxt );
}

sub o_rx_pop_state {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    pop @{$cxt->{states}};

    return $pc + 1;
}

sub o_rx_backtrack {
    my( $op, $runtime, $pc ) = @_;
    my $cxt = $runtime->{_stack}->[-1];

    push @{$cxt->{states}},
         { pos           => $cxt->{pos},
           ret_pc        => $op->{to},
           group_count   => scalar @{$cxt->{groups}},
           saved_groups  => undef,
           };

    return $pc + 1;
}

1;
