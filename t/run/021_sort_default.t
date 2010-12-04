#!/usr/bin/perl -w

print "1..2\n";

@x = sort 7, 10, 4, 5, 2;
print "@x" eq '10 2 4 5 7' ? "ok\n" : "not ok - @x\n";

@x = sort qw(skfd kd k 7j k p);
print "@x" eq '7j k k kd p skfd' ? "ok\n" : "not ok - @x\n";
