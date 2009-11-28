#!/usr/bin/perl -w

print "1..5\n";

$text = 'abbcccddddeeeeeffffff';

# match
print $text =~ /^a/ ? "ok\n" : "not ok\n";
print $text =~ /bc/ ? "ok\n" : "not ok\n";
print $text =~ /de+f/ ? "ok\n" : "not ok\n";

# not match
print $text !~ /bac/ ? "ok\n" : "not ok\n";
print $text !~ /df/ ? "ok\n" : "not ok\n";
