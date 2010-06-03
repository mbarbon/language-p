#!/usr/bin/perl -w

BEGIN { print "1..17\n"; };

sub c1 {
    package p1;
    return main::c2();
}

sub c2 {
    package p2;
    return caller;
}

print defined caller() ? "not ok\n" : "ok\n";
print c1() eq 'p1' ? "ok\n" : "not ok\n";
print c2() eq 'main' ? "ok\n" : "not ok\n";

( $cp1, $cf1, $cl1 ) = c1();
( $cp2, $cf2, $cl2 ) = c2();

print "$cp1 $cf1 $cl1" eq 'p1 t/run/123_caller.t 7' ? "ok\n" : "not ok\n";
print "$cp2 $cf2 $cl2" eq 'main t/run/123_caller.t 20' ? "ok\n" : "not ok\n";

sub cc_scalar {
    my $c = ( caller 0 )[5];

    print( defined $c && !$c ? "ok\n" : "not ok\n" );
}

sub cc_array {
    print( ( caller 0 )[5] ? "ok\n" : "not ok\n" );
}

sub cc_void {
    print( !defined( ( caller 0 )[5] ) ? "ok\n" : "not ok\n" );
}

sub subname { return ( caller 1 )[3]; }
sub hints { return ( caller 0 )[8] & 0xff; }

# context
cc_void();
$x = cc_scalar();
@x = cc_array();

# sub name
sub foo {
    print subname() eq 'main::foo' ? "ok\n" : "not ok\n";
}

foo();

# hints/warnings
print hints() == 0 ? "ok - hints\n" : "not ok - hints\n";;
{
    use strict;
    print hints() == 2 ? "ok\n" : "not ok\n";;
}

print hints() == 0 ? "ok\n" : "not ok\n";;;
{
    BEGIN { $^H = 0x602 }; # use strict;
    print hints() == 2 ? "ok\n" : "not ok\n";;;
}

# eval scopes
eval {
    print subname() eq '(eval)' ? "ok\n" : "not ok\n";
    package x;
    print caller eq 'main' ? "ok\n" : "not ok\n";
};

eval q{
    print subname() eq '(eval)' ? "ok\n" : "not ok\n";
};

# caller in BEGIN blocks
package W;
BEGIN {
    my( $cp, $cf, $cl ) = caller;

    print "$cp $cf $cl" eq 'main t/run/123_caller.t 84' ? "ok\n" : "not ok - $cp $cf $cl\n";
}
