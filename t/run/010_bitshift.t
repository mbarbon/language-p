#!/usr/bin/perl -w

print "1..4\n";

$x = 4;

print $x << 4 == 64 ? "ok\n" : "not ok\n";

$x <<= 4;

print $x == 64 ? "ok\n" : "not ok\n";

print $x >> 4 == 4 ? "ok\n" : "not ok\n";

$x >>= 4;

print $x == 4 ? "ok\n" : "not ok\n";
