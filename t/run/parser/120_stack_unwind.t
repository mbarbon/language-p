#!/usr/bin/perl -w

print "1..9\n";

sub foo {
    local $x = 2;
    die "DIED!";
    local $x = 3;
}

$x = 1;

$ok = eval 'local $x = 2; die "die() in eval"';
print $ok ? "not ok 1\n" : "ok 1\n";
print $@ eq "die() in eval at (eval 1) line 1.\n" ? "ok 2\n" : "not ok 2 - $@\n";
print $x == 1 ? "ok 3\n" : "not ok 3\n";

$ok = eval 'foo()';
print $ok ? "not ok 4\n" : "ok 4\n";
print $@ eq "DIED! at t/run/parser/120_stack_unwind.t line 7.\n" ? "ok 5\n" : "not ok 5 - $@\n";
print $x == 1 ? "ok 6\n" : "not ok 6\n";

$ok = eval 'require file_not_there';
print $ok ? "not ok 7\n" : "ok 7\n";
print $@ =~ m'Can\'t locate file_not_there\.pm in @INC ' ? "ok 8\n" : "not ok 8 - $@\n";

$ok = eval 'sub a 1';
print $ok ? "not ok 9\n" : "ok 9\n";
