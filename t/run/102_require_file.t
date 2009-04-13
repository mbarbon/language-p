#!/usr/bin/perl

# no warnings for redefined sub ok
print "1..4\n";
print "ok 1\n";

@INC = ('t/run/files');

$ok = 2;
$ok = require 'foo.pl';

ok( 3 );

require 'foo.pl';

print "ok $ok\n";
