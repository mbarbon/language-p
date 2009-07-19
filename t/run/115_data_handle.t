#!/usr/bin/perl -w

print "1..1\n";

@data = <DATA>;

print "$data[0]!$data[1]" eq "one line\n!two lines\n" ? "ok\n" : "not ok\n";

__DATA__
one line
two lines
