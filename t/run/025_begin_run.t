#!/usr/bin/perl -w

BEGIN {
    print "1..2\n";

    *ONE = sub { 1 };
    *TWO = sub { 2 };
}

print ONE() == 1 ? "ok\n" : "not ok\n";
print TWO   == 2 ? "ok\n" : "not ok\n";
