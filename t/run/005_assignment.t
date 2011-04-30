#!/usr/bin/perl -w

print "1..11\n";

$t = ( $a, $c, $b ) = ( 1, 3, 2 );

print "$a $b $c $t" eq "1 2 3 3" ? "ok 1\n" : "not ok 1 - $a $b $c $t\n";

( $a, $b, $c ) = ( $c, $b, $a );

print "$a $b $c" eq "3 2 1" ? "ok 2\n" : "not ok 2 - $a $b $c\n";

@x = @y = ( 1, 2, 3 );

print $#x == 2 ? "ok 3\n" : "not ok 3 - $#x\n";
print $#y == 2 ? "ok 4\n" : "not ok 4 - $#y\n";

# check aliasing
$x[0] = 4;
print "$x[0] $x[1] $x[2]" eq '4 2 3' ? "ok\n" : "not ok - $x[0] $x[1] $x[2]\n";
print "$y[0] $y[1] $y[2]" eq '1 2 3' ? "ok\n" : "not ok - $y[0] $y[1] $y[2]\n";

@x = ();

print $#x == -1 ? "ok\n" : "not ok - $#x\n";
print $#y == 2 ? "ok\n" : "not ok - $#y\n";

@z = ( $a, @x, @y ) = ( 1, 2, 3 );

print $#x == 1 ? "ok\n" : "not ok - $#x\n";
print $#y == -1 ? "ok\n" : "not ok - $#y\n";
print $#z == 2 ? "ok\n" : "not ok - $#z\n";
