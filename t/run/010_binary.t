#!/usr/bin/perl -w

print "1..4\n";

$x = "a"; $y = "b";
$z = $x | $y;

print $z eq "c" ? "ok\n" : "not ok - $z\n";

$x = 150; $y = 105;
$z = $x | $y;

print $z == 255 ? "ok\n" : "not ok - $z\n";

$x = "a"; $y = "b";
$z = $x & $y;

print $z eq "`" ? "ok\n" : "not ok - $z\n";

$x = 245; $y = 105;
$z = $x & $y;

print $z == 97 ? "ok\n" : "not ok - $z\n";
