#!/usr/bin/perl -w

print "1..14\n";

%x = ( 'a', 1, 'b', 2, 'c', 3 );
@x = keys %x;
@y = values %x;

print "# @x - @y\n";

print $#x == 2 ? "ok\n" : "not ok\n";
print $#y == 2 ? "ok\n" : "not ok\n";
print $x{$x[0]} == $y[0] ? "ok\n" : "not ok\n";
print $x{$x[1]} == $y[1] ? "ok\n" : "not ok\n";
print $x{$x[2]} == $y[2] ? "ok\n" : "not ok\n";

$index = 0;
while( my( $k, $v ) = each %x ) {
    print $k eq $x[$index] ? "ok\n" : "not ok - $k eq $x[$index]\n";
    print $v eq $y[$index] ? "ok\n" : "not ok - $v eq $y[$index]\n";

    $index += 1;
}

$index = 0;
while( my $k = each %x ) {
    print $k eq $x[$index] ? "ok\n" : "not ok - $k eq $x[$index]\n";

    $index += 1;
}
