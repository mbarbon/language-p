#!/usr/bin/perl -w

print "1..4\n";

$_ = "abcde";
@x = reverse qw(1 4 3 2);

print "@x" eq "2 3 4 1" ? "ok\n" : "not ok - @x\n";

@x = ();
@x = reverse @x;

print "@x" eq "" ? "ok\n" : "not ok - @x\n";

$x = reverse @x;

print $x eq "edcba" ? "ok\n" : "not ok - $x\n";

$x = reverse $x, '12', 'xw';

print $x eq "wx21abcde" ? "ok\n" : "not ok - $x\n";
