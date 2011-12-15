#!/usr/bin/perl -w

print "1..9\n";

$w = 1;
$wr1 = \$w;
$wr2 = \$w;
$wr3 = $wr1;

$$wr2 = 7;

print $$wr1 == 7 ? "ok\n" : "not ok\n";
print $$wr2 == 7 ? "ok\n" : "not ok\n";
print $$wr3 == 7 ? "ok\n" : "not ok\n";

@w = ( 1, 2, 3 );
$wr1 = \@w;
$wre1 = \$w[1];

$$wre1 = 7;

print $w[1]      == 7 ? "ok\n" : "not ok\n";
print ${$wr1}[1] == 7 ? "ok\n" : "not ok\n";
print $$wre1     == 7 ? "ok\n" : "not ok\n";

%w = ( 1, 2, 3, 4, 5, 6 );
$wr1 = \%w;
$wre1 = \$w{3};

$$wre1 = 7;

print $w{3}      == 7 ? "ok\n" : "not ok\n";
print ${$wr1}{3} == 7 ? "ok\n" : "not ok\n";
print $$wre1     == 7 ? "ok\n" : "not ok\n";
