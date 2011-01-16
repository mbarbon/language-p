#!/usr/bin/perl -w

print "1..11\n";

sub moo { print "ok\n"; }
$moo = 42;
@moo = ( 41, 42, 43 );
%moo = ( zz => 42 );

*foo = *moo;

foo();
print $foo == 42 ? "ok\n" : "not ok\n";
print $foo[1] == 42 ? "ok\n" : "not ok\n";
print $foo{zz} == 42 ? "ok\n" : "not ok\n";

*bar = \&moo;
*bar = \$moo;
*bar = \@moo;
*bar = \%moo;

bar();
print $bar == 42 ? "ok\n" : "not ok\n";
print $bar[1] == 42 ? "ok\n" : "not ok\n";
print $bar{zz} == 42 ? "ok\n" : "not ok\n";

$bar = 55;
$bar[1] = 55;
$bar{zz} = 55;

print $foo == 55 ? "ok\n" : "not ok\n";
print $foo[1] == 55 ? "ok\n" : "not ok\n";
print $foo{zz} == 55 ? "ok\n" : "not ok\n";
