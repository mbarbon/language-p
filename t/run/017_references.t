#!/usr/bin/perl -w

print "1..15\n";

$rs = \$s;
$ra = \@a;
$rh = \%h;
$rg = \*g;

$s = 1;
@a = ( 1, 2 );
%h = ( a => 1, b => 2, c => 3 );
$g = 42;
@g = ( 4, 2 );
%g = ( 4 => 2 );

print "ok $$rs\n";
print "ok $ra->[1]\n";
print "ok $rh->{c}\n";

@ca = @$ra;
%ch = %$rh;
@cah = %$rh;

print $ca[1] == 2 ? "ok 4\n" : "not ok 4\n";
print $ch{b} == 2 ? "ok 5\n" : "not ok 5\n";
print    $#cah == 5
      && $cah[1] == $ch{$cah[0]}
      && $cah[3] == $ch{$cah[2]}
      && $cah[5] == $ch{$cah[4]} ? "ok 6\n" : "not ok 6\n";

print ${*$rg} == 42 ? "ok 7\n" : "not ok 7\n";
print $#{*$rg} == 1 ? "ok 8\n" : "not ok 8\n";
print ${*$rg}[1] == 2 ? "ok 9\n" : "not ok 9\n";
print ${*$rg}{4} == 2 ? "ok 10\n" : "not ok 10\n";
print *$rg->{4} == 2 ? "ok 11\n" : "not ok 11\n";

print $#$ra == 1 ? "ok 12\n" : "not ok 12\n";

$aa = [ 0, 1, 4, 9, 16 ];
$ah = { a => 1, b => 4, c => 9, d => 16 };

print $aa->[1] == 1 ? "ok 13\n" : "not ok 13\n";
print $ah->{c} == 9 ? "ok 14\n" : "not ok 14\n";

$aae = [];
$ahe = {};

print $#$aae == -1 ? "ok 15\n" : "not ok 15\n";
