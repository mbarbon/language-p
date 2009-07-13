#!/usr/bin/perl -w

BEGIN {
    eval 'print "1..5\n"';
}

my $y = 2;
my $x = 7;

eval '$x = 2; print "ok 1\n"';

print "ok $x\n";

eval 'my $x; $x = 4;';

$x = $x + 1;

print "ok $x\n";

eval '$x = 4; my $x; $x = 7;';
$y = eval '$y + 2';
eval '$y = $y + 1';

print "ok $x\n";
print "ok $y\n";
