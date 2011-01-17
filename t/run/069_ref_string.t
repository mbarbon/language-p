#!/usr/bin/perl -w

print "1..8\n";

$sn = \1;
$su = \undef;
$ss = \"1";
$sr = \\1;
$g = \*a;
$c = \&foo;
$a = \@a;
$h = \%h;

print "$sn" =~ /^SCALAR\(0x[0-9a-f]+\)$/ ? "ok\n" : "not ok - $sn\n";
print "$su" =~ /^SCALAR\(0x[0-9a-f]+\)$/ ? "ok\n" : "not ok - $su\n";
print "$ss" =~ /^SCALAR\(0x[0-9a-f]+\)$/ ? "ok\n" : "not ok - $ss\n";
print "$sr" =~ /^REF\(0x[0-9a-f]+\)$/ ? "ok\n" : "not ok - $sr\n";
print "$g" =~ /^GLOB\(0x[0-9a-f]+\)$/ ? "ok\n" : "not ok - $g\n";
print "$c" =~ /^CODE\(0x[0-9a-f]+\)$/ ? "ok\n" : "not ok - $c\n";
print "$a" =~ /^ARRAY\(0x[0-9a-f]+\)$/ ? "ok\n" : "not ok - $a\n";
print "$h" =~ /^HASH\(0x[0-9a-f]+\)$/ ? "ok\n" : "not ok - $h\n";
