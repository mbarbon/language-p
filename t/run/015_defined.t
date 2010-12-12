#!/usr/bin/perl -w

print "1..9\n";

print defined( undef ) ? "not ok 1\n" : "ok 1\n";
print defined( 1 )     ? "ok 2\n" : "not ok 2\n";
print defined( '' )    ? "ok 3\n" : "not ok 3\n";

$a_undef = undef;
$a_1 = 1;
$a_empty = '';

print defined( $a_undef ) ? "not ok 4\n" : "ok 4\n";
print defined( $a_1 )     ? "ok 5\n"     : "not ok 5\n";
print defined( $a_empty ) ? "ok 6\n"     : "not ok 6\n";

print defined( @x ) ? "not ok\n" : "ok\n";
print defined( %x ) ? "not ok\n" : "ok\n";
print defined( &x ) ? "not ok\n" : "ok\n";
