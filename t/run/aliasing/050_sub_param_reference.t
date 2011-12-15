#!/usr/bin/perl -w

print "1..6\n";

sub save_args {
    $args = \@_;
}

sub save_arg {
    $arg = \$_[1];
}

$x = 1;
@x = ( 1, 2, 3 );
%x = ( 1, 2, 3, 4, 5, 6 );

save_args( $x, $x[1], $x{3} );

$args->[0] = 7;
$args->[1] = 8;
$args->[2] = 9;

print $x    == 7 ? "ok\n" : "not ok\n";
print $x[1] == 8 ? "ok\n" : "not ok\n";
print $x{3} == 9 ? "ok\n" : "not ok\n";

save_arg( 1, $x, 3 );
$$arg = 4;

print $x == 4 ? "ok\n" : "not ok\n";

save_arg( 1, $x[1], 3 );
$$arg = 5;

print $x[1] == 5 ? "ok\n" : "not ok\n";

save_arg( 1, $x{3}, 3 );
$$arg = 6;

print $x{3} == 6 ? "ok\n" : "not ok\n";
