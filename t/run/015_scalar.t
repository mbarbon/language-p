#!/usr/bin/perl -w

print "1..5\n";

@x = qw(1 2 3);

print scalar 1 == 1 ? "ok\n" : "not ok\n";
print scalar @x == 3 ? "ok\n" : "not ok\n";
print scalar( 3, 1, 2 ) == 2 ? "ok\n" : "not ok\n";
print scalar( 3, @x, 2 ) == 2 ? "ok\n" : "not ok\n";
print scalar( 3, 2, @x ) == 3 ? "ok\n" : "not ok\n";
