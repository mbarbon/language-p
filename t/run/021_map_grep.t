#!/usr/bin/perl -w

print "1..8\n";

@x = map $_ * 2, qw(1 2 3 4);

print $#x == 3 ? "ok\n" : "not ok - $#x\n";
print "@x" eq "2 4 6 8" ? "ok\n" : "not ok - @x\n";

@x = map { $_ / 2 } @x;

print $#x == 3 ? "ok\n" : "not ok - $#x\n";
print "@x" eq "1 2 3 4" ? "ok\n" : "not ok - @x\n";

@x = grep $_ & 1, qw(1 2 3 4);

print $#x == 1 ? "ok\n" : "not ok - $#x\n";
print "@x" eq "1 3" ? "ok\n" : "not ok - @x\n";

@x = grep { $_ > 2 } qw(1 2 3 4);

print $#x == 1 ? "ok\n" : "not ok - $#x\n";
print "@x" eq "3 4" ? "ok\n" : "not ok - @x\n";
