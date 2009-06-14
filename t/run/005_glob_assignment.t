#!/usr/bin/perl -w

print "1..4\n";

*a = *b;

$a = 1;
@b = (1, 2, 3);

print "ok $b\n";
print "ok $a[1]\n";
print "ok $b[2]\n";

*b = sub {
    print "ok 4\n";
};

a();
