#!/usr/bin/perl -w

print "1..7\n";

package Foo;

sub foo { 1 }

package main;

print defined %main:: ? "ok\n" : "not ok\n";
print defined %Foo:: ? "ok\n" : "not ok\n";
print defined %Bar:: ? "not ok\n" : "ok\n";

print exists $main::{"Foo::"} ? "ok\n" : "not ok\n";
print exists $main::{"Bar::"} ? "not ok\n" : "ok\n";
print exists $main::{"Foo::"}{"foo"} ? "ok\n" : "not ok\n";
print exists $main::{"Foo::"}{"bar"} ? "not ok\n" : "ok\n";

