#!/usr/bin/perl -w

print "1..9\n";

sub is_void {
    print !defined wantarray ? "ok\n" : "not ok\n";
    return;
}

sub is_scalar {
    print defined( wantarray ) && !wantarray ? "ok\n" : "not ok\n";
    return;
}

sub is_list {
    print wantarray ? "ok\n" : "not ok\n";
    return;
}

is_void();
@x = is_list();
$x = is_scalar();

sub foo_list {
    is_void();
    return is_list();
}

sub foo_scalar {
    is_void();
    return is_scalar();
}

sub foo_void {
    is_void();
    return is_void();
}

@x = foo_list();
$x = foo_scalar();
foo_void();
