#!/usr/bin/perl -w

print "1..9\n";

( $a, $c, $b ) = ( 1, 3, 2 );

print "$a $b $c" eq "1 2 3" ? "ok 1\n" : "not ok 1\n";

( $a, $b, $c ) = ( $c, $b, $a );

print "$a $b $c" eq "3 2 1" ? "ok 2\n" : "not ok 2\n";

@x = @y = ( 1, 2, 3 );

print $#x == 2 ? "ok 3\n" : "not ok 3\n";
print $#y == 2 ? "ok 4\n" : "not ok 4\n";

@x = ();

print $#x == -1 ? "ok 5\n" : "not ok 5\n";
print $#y == 2 ? "ok 6\n" : "not ok 6\n";

@z = ( $a, @x, @y ) = ( 1, 2, 3 );

print $#x == 1 ? "ok 7\n" : "not ok 7\n";
print $#y == -1 ? "ok 8\n" : "not ok 8\n";
print $#z == 2 ? "ok 9\n" : "not ok 9\n";
