#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 7;
use Test::Differences;

use Language::P::Runtime;
use Language::P::Opcodes qw(o);
use Language::P::Value::Regexp;

my $runtime = Language::P::Runtime->new;

# a*(?:a|b|c)
my @re4 =
  ( o( 'rx_start_match' ),
    # start quantifier
    o( 'rx_start_group', to       => 3 ), # 1
    o( 'rx_exact',       string   => 'a', length => 1 ),
    o( 'rx_quantifier',  to       => 2, min => 0, max => -1 ), # 3
    # end quantifier
    # start alternation
    o( 'rx_try',         fail_to  => 7 ), # 4
    o( 'rx_exact',       string   => 'a', length => 1 ),
    o( 'jump',           to       => 11 ),
    o( 'rx_try',         fail_to  => 10 ), # 7
    o( 'rx_exact',       string   => 'b', length => 1 ),
    o( 'jump',           to       => 11 ),
    o( 'rx_exact',       string   => 'c', length => 1 ), # 10
    # end alternation
    o( 'rx_accept',      groups   => 0 ), # 11
    );
my $re4 = Language::P::Value::Regexp->new
              ( { bytecode   => \@re4,
                  stack_size => 0,
                  } );

# a*(x|b|c)
my @re6 =
  ( o( 'rx_start_match' ),
    # start quantifier
    o( 'rx_start_group', to       => 3 ),
    o( 'rx_exact',       string   => 'a', length => 1 ),
    o( 'rx_quantifier',  to       => 2, min => 0, max => -1 ),
    # end quantifier
    # start capture
    o( 'rx_capture_start', group  => 0 ),
    # start alternation
    o( 'rx_try',         fail_to  => 8 ), # 5
    o( 'rx_exact',       string   => 'x', length => 1 ),
    o( 'jump',           to       => 12 ),
    o( 'rx_try',         fail_to  => 11 ), # 8
    o( 'rx_exact',       string   => 'b', length => 1 ),
    o( 'jump',           to       => 12 ),
    o( 'rx_exact',       string   => 'c', length => 1 ), # 11
    # end alternation
    o( 'rx_capture_end', group    => 0 ), # 12
    # end capture
    o( 'rx_accept',      groups   => 1 ),
    );
my $re6 = Language::P::Value::Regexp->new
              ( { bytecode   => \@re6,
                  stack_size => 0,
                  } );

# ((b)*|(a)*)*w
my @re8 =
  ( o( 'rx_start_match' ),
    # start quantifer
    o( 'rx_start_group', to       => 10 ),
    # start alternation
    o( 'rx_try',         fail_to  => 7, # 2
                         subgroups_start => 1, subgroups_end => 2 ),
    # start quantifier
    o( 'rx_start_group', to       => 5 ), # 3
    o( 'rx_exact',       string   => 'b', length => 1 ),
    o( 'rx_quantifier',  to       => 4, min => 0, max => -1, # 5
                         group => 1,
                         subgroups_start => 1, subgroups_end => 2 ),
    o( 'jump',           to       => 10 ),
    # end quantifier
    # start quantifier
    o( 'rx_start_group', to       => 9 ), # 7
    o( 'rx_exact',       string   => 'a', length => 1 ),
    o( 'rx_quantifier',  to       => 8, min => 0, max => -1, # 9
                         group => 2,
                         subgroups_start => 2, subgroups_end => 3 ),
    # end quantifier
    # end alternation
    o( 'rx_quantifier',  to       => 2, min => 0, max => -1, # 10
                         group => 0,
                         subgroups_start => 0, subgroups_end => 3 ),
    # end quantifier
    o( 'rx_exact',       string   => 'w', length => 1 ), # 11
    o( 'rx_accept',      groups   => 3 ),
    );
my $re8 = Language::P::Value::Regexp->new
              ( { bytecode   => \@re8,
                  stack_size => 0,
                  } );

eq_or_diff( $re4->match( $runtime, 'aadcwwbb' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 2,
              captures    => [],
              } );

eq_or_diff( $re4->match( $runtime, 'aacwwbb' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 3,
              captures    => [],
              } );

eq_or_diff( $re4->match( $runtime, 'aacbb' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 3,
              captures    => [],
              } );

eq_or_diff( $re4->match( $runtime, 'aabb' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 3,
              captures    => [],
              } );

eq_or_diff( $re6->match( $runtime, 'aadcwwbb' ),
            { matched     => 1,
              match_start => 3,
              match_end   => 4,
              captures    => [ [3, 4] ],
              } );

eq_or_diff( $re8->match( $runtime, 'aaw' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 3,
              captures    => [ [2, 2], [-1, -1], [1, 2] ],
              } );

eq_or_diff( $re8->match( $runtime, 'bbw' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 3,
              captures    => [ [2, 2], [-1, -1], [-1, -1] ],
              } );
