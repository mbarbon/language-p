#!/usr/bin/perl -w

print "1..12\n";

$sn = \1;
$su = \undef;
$ss = \"1";
$sr = \\1;
$g = \*a;
$c = \&foo;
$a = \@a;
$h = \%h;

print defined( ref 1 ) ? "ok\n" : "not ok\n";
print defined( ref undef ) ? "ok\n" : "not ok\n";
print ref 1 eq '' ? "ok\n" : "not ok\n";
print ref undef eq '' ? "ok\n" : "not ok\n";
print ref $sn eq 'SCALAR' ? "ok\n" : "not ok\n";
print ref $su eq 'SCALAR' ? "ok\n" : "not ok\n";
print ref $ss eq 'SCALAR' ? "ok\n" : "not ok\n";
print ref $sr eq 'REF' ? "ok\n" : "not ok\n";
print ref $g eq 'GLOB' ? "ok\n" : "not ok\n";
print ref $c eq 'CODE' ? "ok\n" : "not ok\n";
print ref $a eq 'ARRAY' ? "ok\n" : "not ok\n";
print ref $h eq 'HASH' ? "ok\n" : "not ok\n";
