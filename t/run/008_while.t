#!/usr/bin/perl -w

print "1..4\n";

$i = 0;
$j = 1;

while( $i < 0 ) {
    print "not ok\n";
}

while( $i < 3 ) {
    $i = $i + 1;
    print "ok $i\n";
} continue {
    $j = $j + 1;
}

print "ok $j\n";
