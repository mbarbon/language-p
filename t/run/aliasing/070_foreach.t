#!/usr/bin/perl -w

print "1..4\n";

foreach ( $x, $y ) {
    $_ = 7;
}

print $x == 7 ? "ok\n" : "not ok\n";
print $y == 7 ? "ok\n" : "not ok\n";

foreach my $t ( $x, $y ) {
    $t = 8;
}

print $x == 8 ? "ok\n" : "not ok\n";
print $y == 8 ? "ok\n" : "not ok\n";
