#!/usr/bin/perl -w

print "1..4\n";

$a = 1;
$b = 2;

print 1 ? "ok\n" : "not ok\n";
print 0 ? "not ok\n" : "ok\n";
print $a == $a ? "ok\n" : "not ok\n";
print $a == $b ? "not ok\n" : "ok\n";
