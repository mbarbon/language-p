#!/usr/bin/perl -w

print "1..6\n";

@x = ( 1, 2, 3 );

print $x[0] == 1 ? "ok 1\n" : "not ok 1\n";
print $x[2] == 3 ? "ok 2\n" : "not ok 2\n";
print $x[1] == 2 ? "ok 3\n" : "not ok 3\n";

%x = ( 'a', 1, 2, 'b', 'c', 3 );

print $x{a}   == 1   ? "ok 4\n" : "not ok 4\n";
print $x{2}   eq 'b' ? "ok 5\n" : "not ok 5\n";
print $x{'2'} eq 'b' ? "ok 6\n" : "not ok 6\n";
