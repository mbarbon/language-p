#!/usr/bin/perl -w

print "1..2\n";

print chr( 97 ) eq 'a' ? "ok\n" : "not ok\n";
print chr( 0 ) eq "\x00" ? "ok\n" : "not ok\n";
