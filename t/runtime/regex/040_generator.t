#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 9;

use lib 't/lib';
use TestRegex qw(:all);
use Test::Differences;

eq_or_diff( match( 'deadbeef', 'adbe' ),
            { matched     => 1,
              match_start => 2,
              match_end   => 6,
              captures    => [],
              } );

eq_or_diff( match( 'deadbeef', 'a(dbe)' ),
            { matched     => 1,
              match_start => 2,
              match_end   => 6,
              captures    => [ [3, 6] ],
              } );

eq_or_diff( match( 'aadcwwbb', 'a+b+c+' ),
            { matched     => 0,
              } );

eq_or_diff( match( 'aadcwwabbccc', 'a+b+c+' ),
            { matched     => 1,
              match_start => 6,
              match_end   => 12,
              captures    => [],
              } );

eq_or_diff( match( 'aadcwwbb', 'a+' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 2,
              captures    => [],
              } );

eq_or_diff( match( 'aadcwwbb', '(a)+' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 2,
              captures    => [ [1, 2] ],
              } );

eq_or_diff( match( 'aadcwwbb', '(a)+' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 2,
              captures    => [ [1, 2] ],
              } );

eq_or_diff( match( 'aaadcwwbb', '(a*)(a|b|c)' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 3,
              captures    => [ [0, 2], [2, 3] ],
              } );

eq_or_diff( match( 'aaadcwwbb', '(a*?)(a|b|c)' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 1,
              captures    => [ [0, 0], [0, 1] ],
              } );
