#!/usr/bin/perl -w

print "1..3\n";

$x = 1 + 2 * 3 + 4;

print $x == 11 ? "ok 1\n" : "not ok 1\n";

$x = (1 + 2) * (3 + 4);
print $x == 21 ? "ok 2\n" : "not ok 2\n";

$x = 1;
$y = 3;
$z = 7;

print( ( $x + $y ) * $z == 28 ? "ok 3\n" : "not ok 3\n" );
