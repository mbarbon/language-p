#!/usr/bin/perl -w

print "1..6\n";

@a = 4 .. 7;

print $#a == 3 ? "ok\n" : "not ok - $#a\n";
print "$a[0] $a[1] $a[2] $a[3]" eq "4 5 6 7" ? "ok\n" : "not ok - $a[0] $a[1] $a[2] $a[3]\n";

foreach $a ( 3 .. 5 ) {
    print "ok $a\n";
}

foreach $a ( 6 .. 6 ) {
    print "ok $a\n";
}

foreach $a ( 9 .. 7 ) {
    print "ok $a\n";
}

# TODO test string range
# TODO test scalar context behaviour
