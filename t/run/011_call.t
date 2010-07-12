#!/usr/bin/perl -w

print "1..5\n";

sub foo {
    $c = @_;
    print "ok $_[0]\n";
    print $c == 1 ? "ok\n" : "not ok\n";
}

sub bar {
    5;
}

foo( 1 );
foo( 3 );
print "ok " . bar() . "\n";
