#!/usr/bin/perl -w

print "1..5\n";

$x = "abc";

print defined pos( $x ) ? "not ok\n" : "ok\n";

pos( $x ) = 2;
print pos( $x ) == 2 ? "ok\n" : "not ok\n";

pos( $x ) = -2;
print pos( $x ) == 1 ? "ok\n" : "not ok\n";

pos( $x ) = 4;
print pos( $x ) == 3 ? "ok\n" : "not ok\n";

$x .= "d";
print defined pos( $x ) ? "not ok\n" : "ok\n";
