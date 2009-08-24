#!/usr/bin/perl -w

print "1..10\n";

$x = 1 + 2 * 3 + 4;

print $x == 11 ? "ok 1\n" : "not ok 1\n";

$x = (1 + 2) * (3 + 4);
print $x == 21 ? "ok 2\n" : "not ok 2\n";

$x = 1;
$y = 3;
$z = 7;

print( ( $x + $y ) * $z == 28 ? "ok 3\n" : "not ok 3\n" );

$x = .1;
$y = .4;
$z = 84;

print( ( $x + $y ) * $z == 42 ? "ok 4\n" : "not ok 4\n" );

$x = 7;
$y = ++$x;
$z = $x++;

print $x == 9 ? "ok 5\n" : "not ok 5\n";
print $y == 8 ? "ok 6\n" : "not ok 6\n";
print $z == 8 ? "ok 7\n" : "not ok 7\n";

$x = 7;
$y = --$x;
$z = $x--;

print $x == 5 ? "ok 8\n" : "not ok 8\n";
print $y == 6 ? "ok 9\n" : "not ok 9\n";
print $z == 6 ? "ok 10\n" : "not ok 10\n";
