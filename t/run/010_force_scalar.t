#!/usr/bin/perl -w

print "1..8\n";

@x = ( 6, 7, 8, 9, 10 );
@y = ( 3, 4, 5 );

$v = @x + @y + 1;
print $v == 9 ? "ok\n" : "not ok - $v\n";

$v = @x - @y - 1;
print $v == 1 ? "ok\n" : "not ok - $v\n";

$v = 2 * @x * @y;
print $v == 30 ? "ok\n" : "not ok - $v\n";

$v = @y / @x / 2;
print $v == 0.3 ? "ok\n" : "not ok - $v\n";

$v = @x & @y & 7;
print $v == 1 ? "ok\n" : "not ok - $v\n";

$v = @x | @y | 8;
print $v == 15 ? "ok\n" : "not ok - $v\n";

$v = @x ^ @y ^ 2;
print $v == 4 ? "ok\n" : "not ok - $v\n";

$v = -@x;
print $v == -5 ? "ok\n" : "not ok - $v\n";
