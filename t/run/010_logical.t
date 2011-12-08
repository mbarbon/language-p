#!/usr/bin/perl -w

print "1..14\n";

print 2 == ( 1 && 2 ) ? "ok\n" : "not ok\n";
print 0 == ( 0 && 2 ) ? "ok\n" : "not ok\n";
print 2 == ( undef || 2 ) ? "ok\n" : "not ok\n";
print 1 == ( 1 || 2 ) ? "ok\n" : "not ok\n";
print 2 == ( 0 || 2 ) ? "ok\n" : "not ok\n";
print 1 == ( 1 // 2 ) ? "ok\n" : "not ok\n";
print 0 == ( 0 // 2 ) ? "ok\n" : "not ok\n";
print 2 == ( undef // 2 ) ? "ok\n" : "not ok\n";

$a = 1;
$a &&= 2;
print 2 == $a ? "ok\n" : "not ok\n";

$a = 0;
$a &&= 2;
print 0 == $a ? "ok\n" : "not ok\n";

$a = 1;
$a ||= 2;
print 1 == $a ? "ok\n" : "not ok\n";

$a = 0;
$a ||= 2;
print 2 == $a ? "ok\n" : "not ok\n";

$a = 0;
$a //= 2;
print 0 == $a ? "ok\n" : "not ok\n";

$a = undef;
$a //= 2;
print 2 == $a ? "ok\n" : "not ok\n";
