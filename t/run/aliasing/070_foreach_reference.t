#!/usr/bin/perl -w

print "1..7\n";

$x = 1;
@x = ( 1, 2, 3 );
%x = ( 1, 2, 3, 4, 5, 6 );

$r = \$_ foreach $x;
$$r = 7;

print $x == 7 ? "ok\n" : "not ok\n";

$r = \$_ foreach $x[1];
$$r = 7;

print $x[1] == 7 ? "ok\n" : "not ok\n";

$r = \$_ foreach $x{3};
$$r = 7;

print $x{3} == 7 ? "ok\n" : "not ok\n";

$r = \$_ foreach $x[7];
$$r = 7;

print $#x == 7 ? "ok\n" : "not ok\n";
print $x[7] == 7 ? "ok\n" : "not ok\n";

$r = \$_ foreach $x{7};
$$r = 7;

print exists $x{7} ? "ok\n" : "not ok\n";
print $x{7} == 7 ? "ok\n" : "not ok\n";
