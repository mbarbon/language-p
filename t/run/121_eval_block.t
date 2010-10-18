#!/usr/bin/perl

print "1..8\n";

$x = 2;

sub foo {
    ( $p1, $f1, $l1 ) = caller 0;
    ( $p2, $f2, $l2 ) = caller 1;
}

eval {
    local $x = 1;
    print "ok $x\n";
    package x;
    main::foo();
    die "Here\n";
    local $x = 3;
};

print "ok $x\n";
print $@ eq "Here\n" ? "ok 3\n" : "not ok 3 - $@\n";
print "$p1 $f1 $l1" eq "x t/run/121_eval_block.t 16" ? "ok 4\n" : "not ok 4 - $p1 $f1 $l1\n";
print "$p2 $f2 $l2" eq "main t/run/121_eval_block.t 12" ? "ok 5\n" : "not ok 5 - $p2 $f2 $l2\n";

$x = eval {
    print "ok 6\n";
    7;
};
print $x ? "ok $x\n" : "not ok\n";
print $@ ? "not ok\n" : "ok\n";
