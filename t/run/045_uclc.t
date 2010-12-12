#!/usr/bin/perl -w

print "1..5\n";

print uc( 'a' ) eq 'A' ? "ok\n" : "not ok\n";
print lc( 'A' ) eq 'a' ? "ok\n" : "not ok\n";
print uc( 'A' ) eq 'A' ? "ok\n" : "not ok\n";
print lc( 'a' ) eq 'a' ? "ok\n" : "not ok\n";
print uc( '1' ) eq '1' ? "ok\n" : "not ok\n";
