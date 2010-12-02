#!/usr/bin/perl -w

print "1..6\n";

sub tail_sum {
    my( $n, $a ) = @_;
    return $a unless $n;
    @_ = ( $n - 1, $n + $a );
    goto &tail_sum;
}

# too slow for the Toy runtime
# print tail_sum( 60000, 0 ) == 1800030000 ? "ok\n" : "not ok\n";
$sum = tail_sum( 3000, 0 );
print $sum == 4501500 ? "ok\n" : "not ok - $sum\n";

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

sub tail_called {
    my $caller = ( caller( 1 ) )[3];

    return sub { $caller };
}

sub tail_caller {
    goto &{tail_called()};
}

$caller = tail_caller();

print $caller eq 'main::tail_caller' ? "ok\n" : "not ok - $caller\n";
