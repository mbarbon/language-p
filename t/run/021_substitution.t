#!/usr/bin/perl -w

print "1..4\n";

# simple replace
$x = 'abcd';
$x =~ s/c/xx/;

print $x eq 'abxxd' ? "ok\n" : "not ok - $x\n";

# backreferences
$x = 'abcdef';
$x =~ s/(c|e)/x$1/;

print $x eq 'abxcdef' ? "ok\n" : "not ok - $x\n";

# eval
$x = 'abcdef';
$x =~ s/(c|e)/'x' . $1/e;

print $x eq 'abxcdef' ? "ok\n" : "not ok - $x\n";

# global replace
$x = 'abcdef';
$x =~ s/(c|e)/x$1/g;

print $x eq 'abxcdxef' ? "ok\n" : "not ok - $x\n";
