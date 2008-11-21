#!/usr/bin/perl -w

print "1..7\n";

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

for( $k = 5, $l = 4; $k < 7; $k = $k + 1 ) {
    print "ok $k\n";
}

print "ok $k\n";
