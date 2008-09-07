#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 3;
use Test::Differences;

use Language::P::Toy::Runtime;
use Language::P::Toy::Opcodes qw(o);
use Language::P::Toy::Value::Regex;

my $runtime = Language::P::Toy::Runtime->new;

# abc
my @re5 =
  ( o( 'rx_start_match' ),
    o( 'rx_exact',       string   => 'abc', length => 3 ),
    o( 'rx_accept',      groups   => 0 ),
    );

my $re5 = Language::P::Toy::Value::Regex->new
              ( { bytecode   => \@re5,
                  stack_size => 0,
                  } );

eq_or_diff( $re5->match( $runtime, 'abcde' ),
            { matched     => 1,
              match_start => 0,
              match_end   => 3,
              captures    => [],
              } );

eq_or_diff( $re5->match( $runtime, 'abxabcabc' ),
            { matched     => 1,
              match_start => 3,
              match_end   => 6,
              captures    => [],
              } );

eq_or_diff( $re5->match( $runtime, 'aaaaaaaaaaa' ),
            { matched     => 0,
              } );
