#!/usr/bin/perl -w

BEGIN { print "1..4\n"; }
BEGIN { unshift @INC, 'support/bytecode', 'lib' }

package X;

BEGIN {
    $main::INC{'X.pm'} = 'aaa';

    require Exporter;
    @ISA = qw(Exporter);

    @EXPORT = qw(foo bar);
}

sub foo { print "ok\n" }
sub bar { print "ok\n" }

package main;

use X;

foo();
bar();

use X;

foo();
bar();
