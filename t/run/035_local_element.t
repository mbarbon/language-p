#!/usr/bin/perl -w

print "1..8\n";

my @a = ( 0, 1, 2 );
my %a = ( a => 1, b => 2 );

{
    local $a[4] = 5;
    local $a{e} = 5;
    local $a[1];
    local $a{a} = 3;

    print $#a == 4 ? "ok\n" : "not ok\n";
    print exists $a{e} ? "ok\n" : "not ok\n";
    print defined $a[1] ? "not ok\n" : "ok\n";
    print $a{a} == 3 ? "ok\n" : "not ok\n";
}

print $#a == 4 ? "ok\n" : "not ok - $#a\n";
print exists $a{e} ? "not ok\n" : "ok\n";
print $a{a} == 1 ? "ok\n" : "not ok\n";
print $a[1] == 1 ? "ok\n" : "not ok\n";
