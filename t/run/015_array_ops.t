#!/usr/bin/perl -w

print "1..10\n";

push @x, 1, 2;
print $#x == 1 ? "ok 1\n" : "not ok 1\n";
print push(@x, 3, 4) == 4 ? "ok 2\n" : "not ok 2\n";
print $#x == 3 ? "ok 3\n" : "not ok 3\n";
print $x[1] == 2 ? "ok 4\n" : "not ok 4\n";

print pop( @x ) == 4 ? "ok 5\n" : "not ok 5\n";
print $#x == 2 ? "ok 6\n" : "not ok 6\n";

print unshift( @x, 1, 2, 3 ) == 6 ? "ok 7\n" : "not ok 7\n";
print $x[0] == 1 ? "ok 8\n" : "not ok 8\n";
print shift @x == 1 ? "ok 9\n" : "not ok 9\n";
print $#x == 4 ? "ok 10\n" : "not ok 10\n";
