#!/usr/bin/perl -w

print "1..15\n";

$i = 1;

while( $i < 4 ) {
    next if $i > 2;
    print "ok $i\n";
} continue {
    $i = $i + 1;
}

print $i == 4 ? "ok 3\n" : "not ok 3\n";

$j = 1;

while( $j < 4 ) {
    last if $j > 1;
    print "ok 4\n";
} continue {
    $j = $j + 1;
}

print $j == 2 ? "ok 5\n" : "not ok 5\n";

$k = 1;

OUTER: while( $k < 15 ) {
    $l = 1;
    INNER: while( $l < 8 ) {
          last INNER if $l > $k;
          # print "$k $l\n";
          last OUTER if $l + $k > 7;
          $l = $l + 1;
    }
    print $l == $k + 1 ? "ok " . ( $l + 4 ) . "\n" : "not ok\n";
    $k = $k + 1;
}

print $l == $k ? "ok 9\n" : "not ok 9\n";

$k = 1;
$v = 2;
$t = 5;

OUTER: while( $k < 2 ) {
    local $v = 5;
    $l = 1;
    INNER: while( $l < 2 ) {
          local $t = 7;
          last OUTER;
    }
}

print $v == 2 ? "ok 10\n" : "not ok 10\n";
print $t == 5 ? "ok 11\n" : "not ok 11\n";

for( $x = 7; $x < 14; $x = $x + 1 ) {
    next if $x <= 11;
    print "ok $x\n";
}

foreach my $x ( 13, 15 ) {
    next if $x < 14;
    print "ok $x\n";
    last;
} continue {
    print "ok 14\n";
}
