#!/usr/bin/perl -w

sub ok_1 {
    print "ok 1\n";
}

sub ok_7 {
    print "ok 7\n";
}

my $x;

print "ok $x - 4\n";

$x = 6;

BEGIN {
    print "1..7\n";
    ok_1();
    $x = 2;
}

print "ok 5\n";
print "ok $x - 6\n";

BEGIN {
    print "ok $x - 2\n";
    $x = 4;
}

ok_7();

package X;

BEGIN {
    print "ok 3\n";
}
