#!/usr/bin/perl -w

print "1..7\n";

$x = qr/a/;
$y = qr/a/i;
$z = qr/a\)/;

print ref $x eq 'Regexp' ? "ok\n" : "not ok\n";
print $x eq '(?-xism:a)' ? "ok\n" : "not ok - $x\n";
print $y eq '(?i-xsm:a)' ? "ok\n" : "not ok - $y\n";
print $z eq '(?-xism:a\\))' ? "ok\n" : "not ok - $z\n";
print "a" =~ $x ? "ok\n" : "not ok\n";
print "A" =~ $x ? "not ok\n" : "ok\n";
print "A" =~ $y ? "ok\n" : "not ok\n";
