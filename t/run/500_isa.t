#!/usr/bin/perl -w

print "1..11\n";

package A;
package B; @ISA = qw();
package C; @ISA = qw(A B);
package D; @ISA = qw(C);

package main;

print UNIVERSAL->isa( 'UNIVERSAL' ) ? "ok\n" : "not ok\n";
print main->isa( 'UNIVERSAL' ) ? "ok\n" : "not ok\n";
print UNIVERSAL->isa( 'main' ) ? "not ok\n" : "ok\n";
print C->isa( 'A' ) ? "ok\n" : "not ok\n";
print C->isa( 'B' ) ? "ok\n" : "not ok\n";

my $a = bless {}, 'A';
my $b = bless {}, 'B';
my $c = bless {}, 'C';
my $d = bless {}, 'D';

print $a->isa( 'UNIVERSAL' ) ? "ok\n" : "not ok\n";
print $c->isa( 'UNIVERSAL' ) ? "ok\n" : "not ok\n";
print $c->isa( 'A' ) ? "ok\n" : "not ok\n";
print $c->isa( 'B' ) ? "ok\n" : "not ok\n";
print $b->isa( 'A' ) ? "not ok\n" : "ok\n";
print $d->isa( 'B' ) ? "ok\n" : "not ok\n";
