#!/usr/bin/perl -w

print "1..2\n";

sub foo {
    print "ok $_[0]\n";
}

foo( 1 );
foo( 2 );
