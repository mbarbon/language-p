#!/usr/bin/perl -w

print "1..5\n";

BEGIN {
    $x = \&foo;
    $y = \&bar;
}

sub foo { print "ok 1\n" }

$x->();

my $ok = eval {
    Foo::bar();
    1;
};

print defined $ok ? "not ok 2\n" : "ok 2\n";
print $@ =~ /^Undefined subroutine &Foo::bar called at \S+ line \d+.\n/ ? "ok 3\n" : "not ok 3 - $@\n";

my $ok = eval {
    $y->();
    1;
};

print defined $ok ? "not ok 4\n" : "ok 4\n";
print $@ =~ /^Undefined subroutine &main::bar called at \S+ line \d+.\n/ ? "ok 5\n" : "not ok 5 - $@\n";
