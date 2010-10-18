#!/usr/bin/perl -w

print "1..4\n";

print "A" =~ /A/i ? "ok\n" : "not ok\n";
print "a" =~ /A/i ? "ok\n" : "not ok\n";
print "A" =~ /a/i ? "ok\n" : "not ok\n";
print "a" =~ /[A]/i ? "ok\n" : "not ok\n";
