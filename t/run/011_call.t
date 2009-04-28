#!/usr/bin/perl -w

print "1..3\n";

sub foo {
    print "ok $_[0]\n";
}

sub bar {
    3;
}

foo( 1 );
foo( 2 );
print "ok " . bar() . "\n";
