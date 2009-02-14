#!/usr/bin/perl -w

print "1..13\n";

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
    $l = $l + 1;
}

print "ok $k\n";

for my $x ( 8, 9, 10 ) {
    print "ok $x\n";
}

for $k ( 11, 12 ) {
    print "ok $k\n";
}

print $k == 7 ? "ok 13\n" : "not ok 13 - $k\n";
