#!/usr/bin/perl -w

print "1..3\n";

$x = 'abcd';
$x =~ s/c/xx/;

print $x eq 'abxxd' ? "ok\n" : "not ok - $x\n";

$x = 'abcdef';
$x =~ s/(c|e)/x$1/;

print $x eq 'abxcdef' ? "ok\n" : "not ok - $x\n";

$x = 'abcdef';
$x =~ s/(c|e)/'x' . $1/e;

print $x eq 'abxcdef' ? "ok\n" : "not ok - $x\n";
