#!/usr/bin/perl -w

print "1..8\n";

sub fib {
    my( $n ) = @_;

    if( $n >= 2 ) {
        return fib( $n - 2 ) + fib( $n - 1 );
    } else {
        return 1;
    }
}

print fib( 0 ) == 1      ? "ok 1\n" : "not ok 1\n";
print fib( 1 ) == 1      ? "ok 2\n" : "not ok 2\n";
print fib( 2 ) == 2      ? "ok 3\n" : "not ok 3\n";
print fib( 3 ) == 3      ? "ok 4\n" : "not ok 4\n";
print fib( 4 ) == 5      ? "ok 5\n" : "not ok 5\n";
print fib( 10 ) == 89    ? "ok 6\n" : "not ok 6\n";
print fib( 15 ) == 987   ? "ok 7\n" : "not ok 7\n";
print fib( 20 ) == 10946 ? "ok 8\n" : "not ok 8\n";
