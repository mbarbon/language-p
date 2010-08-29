#!/usr/bin/perl -w

print "1..16\n";

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
    print $x ? "ok $x\n" : "not ok\n";
}

for $k ( 11, 12 ) {
    print "ok $k\n";
}

my $r = 8;
for $r ( 13, 14 ) {
    print $r ? "ok $r\n" : "not ok\n";
}

print $k == 7 ? "ok 15\n" : "not ok 15 - $k\n";
print $r == 8 ? "ok 16\n" : "not ok 16 - $r\n";
