#!/usr/bin/perl -w

BEGIN {
    eval 'print "1..10\n"';
}

my $y = 2;
my $x = 7;

eval '$x = 2; print "ok 1\n"';

print "ok $x\n";

eval 'my $x; $x = 4;';

$x = $x + 1;

print "ok $x\n";

eval '$x = 4; my $x; $x = 7;';
$y = eval '$y + 2';
eval '$y = $y + 1';

print "ok $x\n";
print "ok $y\n";

$main::x = $main::x = 66; # avoid warning

package p;
our $x;
package main;
$p::x = 6;

eval 'print "ok $x\n"';

$ok = eval {
    print "ok 7\n";
    8;
};
print "ok $ok\n";

# check that $@ is cleared on enter/exit
$@ = 1;
eval 'print $@ ? "not ok\n" : "ok\n"; $@ = 1';
print $@ ? "not ok\n" : "ok\n";
