#!/usr/bin/perl -w

print "1..10\n";

# simple replace
$x = 'abcd';
print $x =~ s/c/xx/ ? "ok\n" : "not ok\n";
print $x =~ s/z/zz/ ? "no ok\n" : "ok\n";

print $x eq 'abxxd' ? "ok\n" : "not ok - $x\n";

$x =~ s/b/qq/;

print $x eq 'aqqxxd' ? "ok\n" : "not ok - $x\n";

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
$count = $x =~ s/(c|e)/x$1/gc;

print $x eq 'abxcdxef' ? "ok\n" : "not ok - $x\n";
print $count == 2 ? "ok\n" : "not ok - $count\n";
print defined pos $x ? "not ok\n" : "ok\n";
print $1 eq 'e' ? "ok\n" : "not ok\n";
