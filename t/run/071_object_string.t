#!/usr/bin/perl -w

package Foo;

package main;

print "1..3\n";

$s = 1;

$so = \$s;
bless $so, 'Foo';

$ao = [];
bless $ao, 'Foo';

$ho = {};
bless $ho, 'Foo';

print $so =~ /Foo=SCALAR\(0x[0-9a-f]+\)/ ? "ok\n" : "not ok - $so\n";
print $ao =~ /Foo=ARRAY\(0x[0-9a-f]+\)/ ? "ok\n" : "not ok - $ao\n";
print $ho =~ /Foo=HASH\(0x[0-9a-f]+\)/ ? "ok\n" : "not ok - $ho\n";
