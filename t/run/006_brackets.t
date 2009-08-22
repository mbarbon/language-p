#!/usr/bin/perl -w

print "1..18\n";

# elements
@x = ( 1, 2, 3 );

print $x[0] == 1 ? "ok\n" : "not ok\n";
print $x[2] == 3 ? "ok\n" : "not ok\n";
print $x[1] == 2 ? "ok\n" : "not ok\n";
print !defined $x[4] ? "ok\n" : "not ok\n";
print $#x == 2 ? "ok\n" : "not ok\n";

%x = ( 'a', 1, 2, 'b', 'c', 3 );

print $x{a}   == 1   ? "ok\n" : "not ok\n";
print $x{2}   eq 'b' ? "ok\n" : "not ok\n";
print $x{'2'} eq 'b' ? "ok\n" : "not ok\n";
print !defined $x{w} ? "ok\n" : "not ok\n";
print !exists $x{w} ? "ok\n" : "not ok\n";

# slices
@sx = @x[5, 2, 1, 0];

print "$sx[1] $sx[2] $sx[3]" eq "3 2 1" ? "ok\n" : "not ok\n";
print $#x == 2 ? "ok\n" : "not ok\n";
print !defined $sx[0] ? "ok\n" : "not ok\n";

@sx = @x{'z', 'c', 2, 'a'};

print "$sx[1] $sx[2] $sx[3]" eq "3 b 1" ? "ok\n" : "not ok\n";
print !exists $x{z} ? "ok\n" : "not ok\n";
print !defined $sx[0] ? "ok\n" : "not ok\n";

@sx = ()[1, 2, 3];

print $#sx == -1 ? "ok \n" : "not ok\n";

@sx = (7, 6, 5, 4, 3, 2, 1, 0)[3, 2, 1];

print "$sx[0] $sx[1] $sx[2]" eq "4 5 6" ? "ok\n" : "not ok\n";
