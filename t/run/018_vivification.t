#!/usr/bin/perl -w

print "1..7\n";

$x->[1] = 1;

print $x->[1] == 1 ? "ok 1\n" : "not ok 1\n";
print ref( $x ) eq 'ARRAY' ? "ok 2\n" : "not ok 2\n";

$y->{a}[1]{c} = 1;

print $y->{a}->[1]->{c} == 1 ? "ok 3\n" : "not ok 3\n";
print ref( $y ) eq 'HASH' ? "ok 4\n" : "not ok 4\n";
print ref( $y->{a} ) eq 'ARRAY' ? "ok 5\n" : "not ok 5\n";
print ref( $y->{a}->[1] ) eq 'HASH' ? "ok 6\n" : "not ok 6\n";
print ref( $y->{a}->[1]->{c} ) ? "not ok 7\n" : "ok 7\n";
