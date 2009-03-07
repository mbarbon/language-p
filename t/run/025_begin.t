#!/usr/bin/perl -w

sub ok_1 {
    print "ok 1\n";
}

sub ok_6 {
    print "ok 6\n";
}

print "ok 3\n";

my $x = 5;

BEGIN {
    print "1..6\n";
    ok_1();
    $x = 2;
}

print "ok 4\n";
print "ok $x\n";

BEGIN {
    print "ok $x\n";
    $x = 7;
}

ok_6();
