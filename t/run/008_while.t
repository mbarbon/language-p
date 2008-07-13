#!/usr/bin/perl -w

print "1..3\n";

$i = 0;

while( $i < 0 ) {
    print "not ok\n";
}

while( $i < 3 ) {
    $i = $i + 1;
    print "ok $i\n";
}
