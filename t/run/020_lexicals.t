#!/usr/bin/perl -w

print "1..12\n";

print !defined( get() ) ? "ok 1\n" : "not ok 1\n";

my $y = 1;

{
    my $v = 7;

    sub inc { $v = $v + 1 }
    sub get { $v }
}

print get() == 7 ? "ok 2\n" : "not ok 2\n";

inc();
inc();

print get() == 9 ? "ok 3\n" : "not ok 3\n";
print $y == 1 ? "ok 4\n" : "not ok 4\n";

my @y = ( 1, 2, 3 );
my %y = ( a => 1, b => 2, c => 3 );

print $y[2] == 3 ? "ok 5\n" : "not ok 5\n";
print $y{b} == 2 ? "ok 6\n" : "not ok 6\n";

sub test {
    my @x = @_;
    my %x = @x;

    print "ok $x[1]\n";
    print "ok $x{b}\n";
}

test( a => 7, b => 8 );

foreach ( 1, 2 ) {
    my $x = 1;

    print "ok\n";
}

sub test2 {
    foreach ( 1, 2 ) {
        my $x = 1;

        print "ok\n";
    }
}

test2();
