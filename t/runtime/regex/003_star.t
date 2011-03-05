#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;
use Test::Differences;

use Language::P::Toy::Runtime;
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::Regex;

my $runtime = Language::P::Toy::Runtime->new;

# (a)*
my @re3 =
  ( o( 'rx_start_match' ),
    # start quantifier
    o( 'rx_start_group', to       => 5 ),
    o( 'rx_capture_start', group  => 0 ),
    o( 'rx_exact',       characters => 'a', length => 1 ),
    o( 'rx_capture_end', group    => 0 ),
    o( 'rx_quantifier',  to       => 2, min => 0, max => -1, greedy => 1,
                         subgroups_start => 0, subgroups_end => 1,
                         group    => -1 ),
    # end quantifier
    o( 'rx_accept',      groups   => 1 ),
    );
my $re3 = Language::P::Toy::Value::Regex->new
              ( $runtime,
                { bytecode   => \@re3,
                  stack_size => 0,
                  } );

# (a)*(a)
my @re7 =
  ( o( 'rx_start_match' ),
    # start quantifier
    o( 'rx_start_group', to       => 3 ), # 1
    o( 'rx_exact',       characters => 'a', length => 1 ),
    o( 'rx_quantifier',  to       => 2, min => 0, max => -1, greedy => 1, # 3
                         group    => 0,
                         subgroups_start => 0, subgroups_end => 1 ),
    # end quantifier
    o( 'rx_capture_start', group  => 1 ), # 4
    o( 'rx_exact',       characters => 'a', length => 1 ),
    o( 'rx_capture_end', group    => 1 ),
    o( 'rx_accept',      groups   => 2 ),
    );
my $re7 = Language::P::Toy::Value::Regex->new
              ( $runtime,
                { bytecode   => \@re7,
                  stack_size => 0,
                  } );

eq_or_diff( $re3->match( $runtime, 'bb' ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 0,
              captures        => [ [-1, -1] ],
              string_captures => [ undef ],
              } );

eq_or_diff( $re3->match( $runtime, '' ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 0,
              captures        => [ [-1, -1] ],
              string_captures => [ undef ],
              } );

eq_or_diff( $re3->match( $runtime, 'aa' ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 2,
              captures        => [ [1, 2] ],
              string_captures => [ 'a' ],
              } );

eq_or_diff( $re7->match( $runtime, 'aaaa' ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 4,
              captures        => [ [2, 3], [3, 4] ],
              string_captures => [ 'a', 'a' ],
              } );

eq_or_diff( $re7->match( $runtime, 'a' ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 1,
              captures        => [ [-1, -1], [0, 1] ],
              string_captures => [ undef, 'a' ],
              } );

