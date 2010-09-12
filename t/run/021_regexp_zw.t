#!/usr/bin/perl -w

print "1..5\n";

$text = 'abbcccddddeeeeeffffff';

# positive lookahead
print $text =~ /(?=..(.))bb/ ? "ok\n" : "not ok\n";
print $1 eq 'c' ? "ok\n" : "not ok - $1\n";

print $text =~ /(?=bbc)(..)/ ? "ok\n" : "not ok\n";
print $1 eq 'bb' ? "ok\n" : "not ok - $1\n";

print $text =~ /(?=a)b/ ? "not ok\n" : "ok\n";
