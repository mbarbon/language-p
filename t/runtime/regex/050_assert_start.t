#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;

use lib 't/lib';
use TestRegex qw(:all);
use Test::Differences;

eq_or_diff( match( 'test', '^test' ),
            { matched         => 1,
              match_start     => 0,
              match_end       => 4,
              captures        => [],
              string_captures => [],
              } );

eq_or_diff( match( 'atest', '^test' ),
            { matched     => 0,
              } );
