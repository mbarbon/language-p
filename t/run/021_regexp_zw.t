#!/usr/bin/perl -w

print "1..9\n";

$text = 'abbcccddddeeeeeffffff';

# positive lookahead
print $text =~ /(?=..(.))bb/ ? "ok\n" : "not ok\n";
print $1 eq 'c' ? "ok\n" : "not ok - $1\n";

print $text =~ /(?=bbc)(..)/ ? "ok\n" : "not ok\n";
print $1 eq 'bb' ? "ok\n" : "not ok - $1\n";

print $text =~ /(?=a)b/ ? "not ok\n" : "ok\n";

# negative lookahead
print $text =~ /(?!b)b/ ? "not ok\n" : "ok\n";
print $text =~ /(?!..c)b/ ? "not ok\n" : "ok\n";
print $text =~ /(.)(?!b)/ ? "ok \n" : "not ok\n";
print $1 eq 'b' ? "ok\n" : "not ok - $1\n";
