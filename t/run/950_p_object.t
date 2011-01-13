#!/usr/bin/perl -w

BEGIN { print "1..9\n" }
BEGIN { unshift @INC, 'support/bytecode', 'lib' }

package X;

require Language::P::Object;

@ISA = ( 'Language::P::Object' );

__PACKAGE__->mk_accessors( qw(foo bar) );
__PACKAGE__->mk_ro_accessors( qw(moo) );

package main;

$o1 = X->new( { foo => 1, bar => 2, moo => 3 } );
$o2 = X->new;

print $o1->foo == 1 ? "ok\n" : "not ok\n";
print $o1->bar == 2 ? "ok\n" : "not ok\n";
print $o1->moo == 3 ? "ok\n" : "not ok\n";

$o1->foo( 4 );
$o1->bar( 5 );
$o1->moo( 6 );

print $o1->foo == 4 ? "ok\n" : "not ok\n";
print $o1->bar == 5 ? "ok\n" : "not ok\n";
print $o1->moo == 3 ? "ok\n" : "not ok\n";

print defined $o2->foo ? "not ok\n" : "ok\n";
print defined $o2->bar ? "not ok\n" : "ok\n";
print defined $o2->moo ? "not ok\n" : "ok\n";
