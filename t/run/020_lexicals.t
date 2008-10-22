#!/usr/bin/perl -w

print "1..3\n";

print !defined( get() ) ? "ok 1\n" : "not ok 1\n";

{
    my $v = 7;

    sub inc { $v = $v + 1 }
    sub get { $v }
}

print get() == 7 ? "ok 2\n" : "not ok 2\n";

inc();
inc();

print get() == 9 ? "ok 3\n" : "not ok 3\n";
