#!/usr/bin/perl -w

BEGIN { print "1..1\n"; unshift @INC, 't/run/files'; };

sub subname { return ( caller 1 )[3]; }

# eval scopes
eval q{
    print subname() eq '(eval)' ? "ok\n" : "not ok\n";
};
