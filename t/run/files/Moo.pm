package Moo;

print "ok 1\n";

sub import {
    print "ok $_[1]\n";
}

sub unimport {
    print "ok 3\n";
}

sub ok_moo {
    print "ok $_[0]\n";
}

1;
