#!/usr/bin/perl -w

print "1..8\n";

sub foo {
    local $x = 7;

    print $x == 7 ? "ok 5\n" : "not ok 5 - $x\n";
}

sub boo {
    local $x = 8;

    {
        print $x == 8 ? "ok 7\n" : "not ok 7 - $x\n";

        return;
    }
}

$x = 0;

local $x = 1;

print $x == 1 ? "ok 1\n" : "not ok 1 - $x\n";

{
    local $x = 3;

    print $x == 3 ? "ok 2\n" : "not ok 2 - $x\n";

    local $x = 5;

    print $x == 5 ? "ok 3\n" : "not ok 3 - $x\n";
}

print $x == 1 ? "ok 4\n" : "not ok 4 - $x\n";

foo();

print $x == 1 ? "ok 6\n" : "not ok 6 - $x\n";

boo();

print $x == 1 ? "ok 8\n" : "not ok 8 - $x\n";
