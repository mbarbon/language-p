#!/usr/bin/perl

# no warnings for redefined sub ok
print "1..5\n";
print "ok 1\n";

$ok = 2;
$ok = do 't/run/files/foo.pl';

ok( 3 );

do 't/run/files/foo.pl';

print "ok 5\n";
