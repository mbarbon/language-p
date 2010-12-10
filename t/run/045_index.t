#!/usr/bin/perl -w

print "1..4\n";

print index( "abbc", "b" ) == 1 ? "ok\n" : "not ok\n";
print index( "abbc", "z" ) == -1 ? "ok\n" : "not ok\n";
print index( "abbc", "b", 2 ) == 2 ? "ok\n" : "not ok\n";
print index( "abbc", "3" ) == -1 ? "ok\n" : "not ok\n";
