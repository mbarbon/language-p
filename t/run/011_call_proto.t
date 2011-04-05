#!/usr/bin/perl -w

print "1..1\n";

sub FOO() { 3 }

$y = 0;
# checks the prototype is used at parse time
$x = FOO & ~$y;

print $x == 3 ? "ok\n" : "not ok\n";
