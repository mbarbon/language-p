#!/usr/bin/perl -w

print "1..17\n";

%x = ( 'a', 1, 'b', 2, 'c', 3 );
@x = keys %x;
@y = values %x;

print "# @x - @y\n";

print $#x == 2 ? "ok\n" : "not ok - $#x\n";
print $#y == 2 ? "ok\n" : "not ok - $#y\n";
print $x{$x[0]} == $y[0] ? "ok\n" : "not ok - $x{$x[0]} $y[0]\n";
print $x{$x[1]} == $y[1] ? "ok\n" : "not ok - $x{$x[1]} $y[1]\n";
print $x{$x[2]} == $y[2] ? "ok\n" : "not ok - $x{$x[2]} $y[2]\n";

$index = 0;
while( my( $k, $v ) = each %x ) {
    print $k eq $x[$index] ? "ok\n" : "not ok - $k eq $x[$index]\n";
    print $v eq $y[$index] ? "ok\n" : "not ok - $v eq $y[$index]\n";

    $index = $index + 1;
}

$index = 0;
while( my $k = each %x ) {
    print $k eq $x[$index] ? "ok\n" : "not ok - $k eq $x[$index]\n";

    $index = $index + 1;
}

print exists $x{b} ? "ok\n" : "not ok\n";
$d = delete $x{b};
print $d == 2 ? "ok\n" : "not ok\n";
print exists $x{b} ? "not ok\n" : "ok\n";
