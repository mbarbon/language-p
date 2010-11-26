#!/usr/bin/perl -w

print "1..3\n";

print length( "321" ) == 3 ? "ok\n" : "not ok\n";
print length( 01234 ) == 3 ? "ok\n" : "not ok\n";
print length( @x )    == 1 ? "ok\n" : "not ok\n";
