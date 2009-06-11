#!/usr/bin/perl -w

print "1..6\n";

$rs = \$s;
$ra = \@a;
$rh = \%h;

$s = 1;
@a = ( 1, 2 );
%h = ( a => 1, b => 2, c => 3 );

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
