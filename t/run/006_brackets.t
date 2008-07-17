#!/usr/bin/perl -w

print "1..3\n";

@x = ( 1, 2, 3 );

print $x[0] == 1 ? "ok 1\n" : "not ok 1\n";
print $x[2] == 3 ? "ok 2\n" : "not ok 2\n";
print $x[1] == 2 ? "ok 3\n" : "not ok 3\n";
