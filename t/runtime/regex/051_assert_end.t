#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;

use lib 't/lib';
use TestRegex qw(:all);
use Test::Differences;

eq_or_diff( match( "test", 'test$' ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 4,
              captures        => [],
              string_captures => [],
              } );

eq_or_diff( match( "test\n", 'test$' ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 4,
              captures        => [],
              string_captures => [],
              } );

eq_or_diff( match( "test\n", 'test\n$' ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 5,
              captures        => [],
              string_captures => [],
              } );

eq_or_diff( match( "test\n", "test\$\n" ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 5,
              captures        => [],
              string_captures => [],
              } );

eq_or_diff( match( 'testa', 'test$' ),
            { matched     => 0,
              } );
