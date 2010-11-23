#!/usr/bin/perl -w

print "1..6\n";

$x = "\x04\xf0";

print vec( $x, 2, 1 ) == 1 ? "ok\n" : "not ok\n";
print vec( $x, 0, 4 ) == 4 ? "ok\n" : "not ok\n";
print vec( $x, 1, 4 ) == 0 ? "ok\n" : "not ok\n";

vec( $x, 2, 2 ) = 7;

print vec( $x, 1, 2 ) == 1 ? "ok\n" : "not ok\n";
print vec( $x, 2, 2 ) == 3 ? "ok\n" : "not ok\n";
print vec( $x, 3, 2 ) == 0 ? "ok\n" : "not ok\n";
