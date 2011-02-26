#!/usr/bin/perl -w

BEGIN { print "1..4\n"; }
BEGIN { unshift @INC, 'support/bytecode', 'lib' }

package X;

BEGIN {
    $main::INC{'X.pm'} = 'aaa';

    require Exporter;
    @ISA = qw(Exporter);

    @EXPORT = qw(%FOO $BAR @BAZ &moo *moo);
}

%FOO = ( a => 1, b => 2 );
$BAR = 42;
@BAZ = ( 2, 3, 4 );
sub moo { print "ok - moo\n" }

package main;

use X;

print $BAR == 42 ? "ok\n" : "not ok - $FOO\n";
print $BAZ[1] == 3 ? "ok\n" : "not ok - $FOO\n";
print $FOO{b} == 2 ? "ok\n" : "not ok - $FOO\n";
moo();
