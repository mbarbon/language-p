#!/usr/bin/perl -w

print "1..5\n";

sub tail_sum {
    my( $n, $a ) = @_;
    return $a unless $n;
    @_ = ( $n - 1, $n + $a );
    goto &tail_sum;
}

# too slow for the Toy runtime
# print tail_sum( 60000, 0 ) == 1800030000 ? "ok\n" : "not ok\n";
print tail_sum( 3000, 0 ) == 4501500 ? "ok\n" : "not ok\n";

$t = 4;
$c = 0;
sub tail_local {
    print $t == 4 ? "ok\n" : "not ok\n";
    local $t = 8;
    print $t == 8 ? "ok\n" : "not ok\n";
    ++$c;
    goto &tail_local if $c == 1;
}

tail_local;
