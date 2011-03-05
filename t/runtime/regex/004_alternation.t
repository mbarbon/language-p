#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;
use Test::Differences;

use Language::P::Toy::Runtime;
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::Regex;

my $runtime = Language::P::Toy::Runtime->new;

# (a|b|c)x
my @re1 =
  ( o( 'rx_start_match' ),
    o( 'rx_capture_start', group  => 0 ),
    # start alternation
    # first
    o( 'rx_try',         to       => 5 ), # 2
    o( 'rx_exact',       characters => 'a', length => 1 ),
    o( 'jump',           to       => 9 ),
    # second
    o( 'rx_try',         to       => 8 ), # 5
    o( 'rx_exact',       characters => 'b', length => 1 ),
    o( 'jump',           to       => 9 ),
    # last
    o( 'rx_exact',       characters => 'c', length => 1 ), # 8
    # end alternation
    o( 'rx_capture_end', group    => 0 ), # 9
    o( 'rx_exact',       characters => 'x', length => 1 ),
    o( 'rx_accept',      groups   => 0 ),
    );
my $re1 = Language::P::Toy::Value::Regex->new
              ( $runtime,
                { bytecode   => \@re1,
                  stack_size => 0,
                  } );

eq_or_diff( $re1->match( $runtime, 'fdsdjkgddskj' ),
            { matched     => 0,
              } );

eq_or_diff( $re1->match( $runtime, 'qqac' ),
            { matched     => 0,
              } );

eq_or_diff( $re1->match( $runtime, 'qqax' ),
            { matched         => 1,
              match_start     => 2,
              match_end       => 4,
              captures        => [ [ 2, 3 ] ],
              string_captures => [ 'a' ],
              } );

eq_or_diff( $re1->match( $runtime, 'qqacbbx' ),
            { matched         => 1,
              match_start     => 5,
              match_end       => 7,
              captures        => [ [ 5, 6 ] ],
              string_captures => [ 'b' ],
              } );
