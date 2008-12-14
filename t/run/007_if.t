#!/usr/bin/perl -w

print "1..4\n";

$a = 1;

if( $a < 2 ) {
    print "ok 1\n";
} elsif( $a < 3 ) {
    print "not ok 1\n";
} else {
    print "not ok 1\n";
}

$a = 2;

if( $a < 2 ) {
    print "not ok 2\n";
} elsif( $a < 3 ) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

$a = 3;

if( $a < 2 ) {
    print "not ok 3\n";
} elsif( $a < 3 ) {
    print "not ok 3\n";
} else {
    print "ok 3\n";
}

unless( $a < 2 ) {
    print "ok 4\n";
} else {
    print "not ok 4\n";
}
