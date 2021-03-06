#!/usr/bin/perl -w

print "1..6\n";

$x = do {
    1;
    2;
};

print $x == 2 ? "ok\n" : "not ok - $x\n";

$y = do {
    local $x = 1;
    2;
    3;
};

print $x == 2 ? "ok\n" : "not ok - $x\n";
print $y == 3 ? "ok\n" : "not ok - $y\n";

# in conditions
$x = 1;

while( do { $c = $x } ) {
    print "ok 4\n";
    $x = $x - 1;
}

$x = 1;

while( do { my $c = $x } ) {
    print "ok 5\n";
    $x = $x - 1;
}

if( !do { my $c = $x } ) {
    print "ok 6\n";
}
