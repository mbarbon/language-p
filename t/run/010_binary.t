#!/usr/bin/perl -w

print "1..2\n";

$x = "a"; $y = "b";
$z = $x | $y;

print $z eq "c" ? "ok\n" : "not ok - $z\n";

$x = 150; $y = 105;
$z = $x | $y;

print $z == 255? "ok\n" : "not ok - $z\n";
