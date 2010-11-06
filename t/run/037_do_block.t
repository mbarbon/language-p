#!/usr/bin/perl -w

print "1..3\n";

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
