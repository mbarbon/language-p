#!/usr/bin/perl -w

package Foo;

sub a { $_[0]->{a} }

package Bar;

@ISA = 'Foo';

sub a { $_[0]->{b} }
sub b { $_[0]->SUPER::a }

package Baz;

@ISA = 'Bar';

sub a { $_[0]->{c} }
sub b { $_[0]->SUPER::a }

package Moo;

@ISA = ( 'Foo', 'Bar' );

sub b { $_[0]->SUPER::b }

package main;

print "1..6\n";

$obar = bless { a => 1, b => 3, c => 5 }, 'Bar';
$obaz = bless { a => 1, b => 3, c => 5 }, 'Baz';
$omoo = bless { a => 1, b => 3, c => 5 }, 'Moo';

print $obar->a == 3 ? "ok\n" : "not ok\n";
print $obar->b == 1 ? "ok\n" : "not ok\n";

print $obaz->a == 5 ? "ok\n" : "not ok\n";
print $obaz->b == 3 ? "ok\n" : "not ok\n";
print $obaz->Bar::b == 1 ? "ok\n" : "not ok\n";

# multiple inheritance
print $omoo->b == 1 ? "ok\n" : "not ok\n";
