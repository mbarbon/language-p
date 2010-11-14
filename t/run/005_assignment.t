#!/usr/bin/perl -w

print "1..14\n";

# array assignment (scalar and list context)
$t = ( $a, $c, $b ) = ( 1, 3, 2 );

print "$a $b $c $t" eq "1 2 3 3" ? "ok 1\n" : "not ok 1 - $a $b $c $t\n";

( $a, $b, $c ) = ( $c, $b, $a );

print "$a $b $c" eq "3 2 1" ? "ok 2\n" : "not ok 2 - $a $b $c\n";

@x = @y = ( 1, 2, 3 );

print $#x == 2 ? "ok 3\n" : "not ok 3 - $#x\n";
print $#y == 2 ? "ok 4\n" : "not ok 4 - $#y\n";

@x = ();

print $#x == -1 ? "ok 5\n" : "not ok 5 - $#x\n";
print $#y == 2 ? "ok 6\n" : "not ok 6 - $#y\n";

# hash assignment (scalar and list context)
$t = %x = ( 1, 3, 2, 5 );

print "$x{1} $x{2} $t" eq "3 5 4" ? "ok 7\n" : "not ok 7 - $x{1} $x{2} $t\n";

# array in lvalue context
@z = ( $a, @x, @y ) = ( 1, 2, 3 );

print $#x == 1 ? "ok\n" : "not ok - $#x\n";
print $#y == -1 ? "ok\n" : "not ok - $#y\n";
print $#z == 2 ? "ok\n" : "not ok - $#z\n";

# hash in lvalue context
@z = ( $a, %x, %y ) = ( 1, 2, 3, 4 ,5 );

print $a == 1 ? "ok 11\n" : "not ok 11 - $a\n";
print $x{2} == 3 ? "ok\n" : "not ok - $x{2}\n";
print $x{4} == 5 ? "ok\n" : "not ok - $x{4}\n";
print $#z == 4 ? "ok\n" : "not ok - $#z\n";
