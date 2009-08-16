#!/usr/bin/perl -w

print "1..5\n";

sub foo {
    local $x = 2;
    die "DIED!";
    local $x = 3;
}

$x = 1;

eval 'local $x = 2; die "die() in eval"';
print $@ eq "die() in eval at <string> line 1.\n" ? "ok 1\n" : "not ok 1\n";
print $x == 1 ? "ok 2\n" : "not ok 2\n";
eval 'foo()';
print $@ eq "DIED! at t/run/120_stack_unwind.t line 7.\n" ? "ok 3\n" : "not ok 3\n";
print $x == 1 ? "ok 4\n" : "not ok 4\n";

eval 'require file_not_there';
print $@ =~ m'Can\'t locate file_not_there.pm in @INC ' ? "ok 5\n" : "not ok 5\n";
