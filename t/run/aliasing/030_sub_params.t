#!/usr/bin/perl -w

print "1..5\n";

sub sub_plain {
    $_[1] = 7;
}

sub sub_shift {
    shift;

    $_[1] = 7;
}

sub sub_unshift {
    unshift @_, 1;

    $_[1] = 7;
}

sub sub_splice {
    splice @_, 0, 1, 7;

    $_[1] = 7;
}

sub sub_unalias {
    @_ = ( 7, 7, 7 );

    $_[1] = 7;
}


$x = 0;
sub_plain( 1, $x, 2 );

print $x == 7 ? "ok\n" : "not ok\n";

$x = 0;
sub_shift( 1, 2, $x, 3 );

print $x == 7 ? "ok\n" : "not ok\n";

$x = 0;
sub_unshift( $x, 3 );

print $x == 7 ? "ok\n" : "not ok\n";

$x = 0;
sub_splice( 1, $x, 2 );

print $x == 7 ? "ok\n" : "not ok\n";

$x = 0;
sub_unalias( 1, $x, 2 );

print $x == 0 ? "ok\n" : "not ok\n";
