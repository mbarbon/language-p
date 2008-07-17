#!/usr/bin/perl -w

print "1..3\n";

( $a, $c, $b ) = ( 1, 3, 2 );

print "$a $b $c" eq "1 2 3" ? "ok 1\n" : "not ok 1\n";

( $a, $b, $c ) = ( $c, $b, $a );

print "$a $b $c" eq "3 2 1" ? "ok 2\n" : "not ok 2\n";

@x = ( 1, 2, 3 );

print $#x == 2 ? "ok 3\n" : "not ok 3\n";

# @x = ();

# print $#x == -1 ? "ok 4\n" : "not ok 4\n";
