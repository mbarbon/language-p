#!/usr/bin/perl -w

print "1..9\n";

$x = "\x04\xf0";

print vec( $x, 2, 1 ) == 1 ? "ok\n" : "not ok\n";
print vec( $x, 0, 4 ) == 4 ? "ok\n" : "not ok\n";
print vec( $x, 1, 4 ) == 0 ? "ok\n" : "not ok\n";
print vec( $x, 9, 4 ) == 0 ? "ok\n" : "not ok\n";

vec( $x, 2, 2 ) = 7;

print vec( $x, 1, 2 ) == 1 ? "ok\n" : "not ok\n";
print vec( $x, 2, 2 ) == 3 ? "ok\n" : "not ok\n";
print vec( $x, 3, 2 ) == 0 ? "ok\n" : "not ok\n";

vec( $x, 8, 4 ) = 7;

print vec( $x, 8, 4 ) == 7 ? "ok\n" : "not ok\n";

print $x eq "4\xf0\x00\x00\x07" ? "ok\n" : "not ok\n";
