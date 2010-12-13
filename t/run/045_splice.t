#!/usr/bin/perl -w

print "1..16\n";

@x = qw(a b c d e f);
@y = splice @x, 1, 2, qw(1 2 3 4);

print "@x" eq "a 1 2 3 4 d e f" ? "ok\n" : "not ok - @x\n";
print "@y" eq "b c" ? "ok\n" : "not ok - @y\n";

@x = qw(a b c d e f);
@y = splice @x, 1, 2, 1, 2, 3, 4;

print "@x" eq "a 1 2 3 4 d e f" ? "ok\n" : "not ok - @x\n";
print "@y" eq "b c" ? "ok\n" : "not ok - @y\n";

@x = qw(a b c d e f);
@y = splice @x, 1, 2, qw(1);

print "@x" eq "a 1 d e f" ? "ok\n" : "not ok - @x\n";
print "@y" eq "b c" ? "ok\n" : "not ok - @y\n";

@x = qw(a b c d e f);
@y = splice @x, 1, 3;

print "@x" eq "a e f" ? "ok\n" : "not ok - @x\n";
print "@y" eq "b c d" ? "ok\n" : "not ok - @y\n";

@x = qw(a b c d e f);
@y = splice @x, 1, -2;

print "@x" eq "a e f" ? "ok\n" : "not ok - @x\n";
print "@y" eq "b c d" ? "ok\n" : "not ok - @y\n";

@x = qw(a b c d e f);
@y = splice @x, 3;

print "@x" eq "a b c" ? "ok\n" : "not ok - @x\n";
print "@y" eq "d e f" ? "ok\n" : "not ok - @y\n";

@x = qw(a b c d e f);
@y = splice @x, -2;

print "@x" eq "a b c d" ? "ok\n" : "not ok - @x\n";
print "@y" eq "e f" ? "ok\n" : "not ok - @y\n";

@x = qw(a b c d e f);
@y = splice @x;

print "@x" eq "" ? "ok\n" : "not ok - @x\n";
print "@y" eq "a b c d e f" ? "ok\n" : "not ok - @y\n";
